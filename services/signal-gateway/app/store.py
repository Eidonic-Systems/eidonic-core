import json
import os
from datetime import datetime
from pathlib import Path
from typing import Protocol

import psycopg
from fastapi import HTTPException
from eidonic_schemas import SignalRecord


class SignalStore(Protocol):
    @property
    def backend_name(self) -> str: ...

    def upsert(self, record: SignalRecord) -> SignalRecord: ...

    def get(self, signal_id: str) -> SignalRecord | None: ...

    def list_recent(self, limit: int = 50) -> list[SignalRecord]: ...

    def ping(self) -> dict[str, str]: ...


class LocalJsonSignalStore:
    def __init__(self, store_path: Path):
        self.store_path = store_path
        self.data_dir = store_path.parent
        self._ensure_store()

    @property
    def backend_name(self) -> str:
        return "local_json"

    def _ensure_store(self) -> None:
        self.data_dir.mkdir(parents=True, exist_ok=True)
        if not self.store_path.exists():
            self.store_path.write_text("[]", encoding="utf-8")

    def _load_records(self) -> list[SignalRecord]:
        self._ensure_store()
        raw = self.store_path.read_text(encoding="utf-8").strip()
        if not raw:
            return []
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=500, detail=f"Signal store is invalid JSON: {exc}") from exc
        if not isinstance(data, list):
            raise HTTPException(status_code=500, detail="Signal store must contain a JSON list.")
        return [SignalRecord.model_validate(item) for item in data]

    def _save_records(self, records: list[SignalRecord]) -> None:
        self._ensure_store()
        payload = [record.model_dump() for record in records]
        self.store_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def upsert(self, record: SignalRecord) -> SignalRecord:
        records = self._load_records()
        updated = False
        for index, existing in enumerate(records):
            if existing.signal_id == record.signal_id:
                records[index] = record
                updated = True
                break
        if not updated:
            records.append(record)
        self._save_records(records)
        return record

    def get(self, signal_id: str) -> SignalRecord | None:
        records = self._load_records()
        for record in records:
            if record.signal_id == signal_id:
                return record
        return None

    def list_recent(self, limit: int = 50) -> list[SignalRecord]:
        records = self._load_records()
        ordered = sorted(records, key=lambda record: record.created_at, reverse=True)
        return ordered[:limit]

    def ping(self) -> dict[str, str]:
        self._ensure_store()
        return {
            "status": "ok",
            "backend": self.backend_name,
            "store_path": str(self.store_path),
        }


class PostgresSignalStore:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self._ensure_schema()

    @property
    def backend_name(self) -> str:
        return "postgres"

    def _connect(self):
        return psycopg.connect(self.dsn)

    def _row_to_record(self, row: dict) -> SignalRecord:
        data = dict(row)

        created_at = data.get("created_at")
        if isinstance(created_at, datetime):
            data["created_at"] = created_at.isoformat()

        content = data.get("content")
        if isinstance(content, str):
            try:
                data["content"] = json.loads(content)
            except json.JSONDecodeError:
                pass

        metadata = data.get("metadata")
        if isinstance(metadata, str):
            try:
                data["metadata"] = json.loads(metadata)
            except json.JSONDecodeError:
                pass

        return SignalRecord.model_validate(data)

    def _ensure_schema(self) -> None:
        ddl = """
        create table if not exists signal_records (
            signal_id text primary key,
            schema_version text not null,
            signal_type text not null,
            source text not null,
            content jsonb not null,
            created_at timestamptz not null,
            session_hint text null,
            sensitivity_hint text null,
            metadata jsonb not null,
            status text not null,
            storage_backend text not null
        );
        create index if not exists idx_signal_records_created_at on signal_records (created_at desc);
        """
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(ddl)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to initialize Postgres signal store: {exc}") from exc

    def upsert(self, record: SignalRecord) -> SignalRecord:
        sql = """
        insert into signal_records (
            signal_id, schema_version, signal_type, source, content, created_at, session_hint, sensitivity_hint, metadata, status, storage_backend
        ) values (
            %(signal_id)s, %(schema_version)s, %(signal_type)s, %(source)s, %(content)s::jsonb, %(created_at)s::timestamptz, %(session_hint)s, %(sensitivity_hint)s, %(metadata)s::jsonb, %(status)s, %(storage_backend)s
        )
        on conflict (signal_id) do update set
            schema_version = excluded.schema_version,
            signal_type = excluded.signal_type,
            source = excluded.source,
            content = excluded.content,
            created_at = excluded.created_at,
            session_hint = excluded.session_hint,
            sensitivity_hint = excluded.sensitivity_hint,
            metadata = excluded.metadata,
            status = excluded.status,
            storage_backend = excluded.storage_backend;
        """
        data = record.model_dump(mode="json")
        data["content"] = json.dumps(data["content"])
        data["metadata"] = json.dumps(data["metadata"])
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(sql, data)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to upsert signal record in Postgres: {exc}") from exc
        return record

    def get(self, signal_id: str) -> SignalRecord | None:
        sql = """
        select signal_id, schema_version, signal_type, source, content, created_at, session_hint, sensitivity_hint, metadata, status, storage_backend
        from signal_records
        where signal_id = %(signal_id)s
        limit 1;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"signal_id": signal_id})
                    row = cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to fetch signal record from Postgres: {exc}") from exc
        if row is None:
            return None
        return self._row_to_record(row)

    def list_recent(self, limit: int = 50) -> list[SignalRecord]:
        sql = """
        select signal_id, schema_version, signal_type, source, content, created_at, session_hint, sensitivity_hint, metadata, status, storage_backend
        from signal_records
        order by created_at desc
        limit %(limit)s;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"limit": limit})
                    rows = cur.fetchall()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to list signal records from Postgres: {exc}") from exc
        return [self._row_to_record(row) for row in rows]

    def ping(self) -> dict[str, str]:
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute("select 1;")
                    cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Postgres signal store health check failed: {exc}") from exc
        return {
            "status": "ok",
            "backend": self.backend_name,
            "dsn": self.dsn,
        }


def build_signal_store(store_path: Path) -> SignalStore:
    backend = os.getenv("SIGNAL_GATEWAY_STORE_BACKEND", "local_json").strip().lower()
    if backend == "postgres":
        dsn = os.getenv("SIGNAL_GATEWAY_POSTGRES_DSN", "").strip()
        if not dsn:
            raise RuntimeError("SIGNAL_GATEWAY_POSTGRES_DSN is required when SIGNAL_GATEWAY_STORE_BACKEND=postgres")
        return PostgresSignalStore(dsn)
    return LocalJsonSignalStore(store_path)
