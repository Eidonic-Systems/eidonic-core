import json
import os
from datetime import datetime
from pathlib import Path
from typing import Protocol

import psycopg
from fastapi import HTTPException
from eidonic_schemas import SessionRecord


class SessionStore(Protocol):
    @property
    def backend_name(self) -> str: ...

    def upsert(self, record: SessionRecord) -> SessionRecord: ...

    def get(self, session_id: str) -> SessionRecord | None: ...

    def list_recent(self, limit: int = 50) -> list[SessionRecord]: ...

    def ping(self) -> dict[str, str]: ...


class LocalJsonSessionStore:
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

    def _load_records(self) -> list[SessionRecord]:
        self._ensure_store()
        raw = self.store_path.read_text(encoding="utf-8").strip()
        if not raw:
            return []
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=500, detail=f"Session store is invalid JSON: {exc}") from exc
        if not isinstance(data, list):
            raise HTTPException(status_code=500, detail="Session store must contain a JSON list.")
        return [SessionRecord.model_validate(item) for item in data]

    def _save_records(self, records: list[SessionRecord]) -> None:
        self._ensure_store()
        payload = [record.model_dump() for record in records]
        self.store_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def upsert(self, record: SessionRecord) -> SessionRecord:
        records = self._load_records()
        updated = False
        for index, existing in enumerate(records):
            if existing.session_id == record.session_id:
                records[index] = record
                updated = True
                break
        if not updated:
            records.append(record)
        self._save_records(records)
        return record

    def get(self, session_id: str) -> SessionRecord | None:
        records = self._load_records()
        for record in records:
            if record.session_id == session_id:
                return record
        return None

    def list_recent(self, limit: int = 50) -> list[SessionRecord]:
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


class PostgresSessionStore:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self._ensure_schema()

    @property
    def backend_name(self) -> str:
        return "postgres"

    def _connect(self):
        return psycopg.connect(self.dsn)

    def _row_to_record(self, row: dict) -> SessionRecord:
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

        return SessionRecord.model_validate(data)

    def _ensure_schema(self) -> None:
        ddl = """
        create table if not exists session_records (
            session_id text primary key,
            signal_id text not null,
            signal_type text not null,
            source text not null,
            threshold_result text not null,
            content jsonb not null,
            status text not null,
            created_at timestamptz not null,
            storage_backend text not null
        );
        create index if not exists idx_session_records_created_at on session_records (created_at desc);
        """
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(ddl)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to initialize Postgres session store: {exc}") from exc

    def upsert(self, record: SessionRecord) -> SessionRecord:
        sql = """
        insert into session_records (
            session_id, signal_id, signal_type, source, threshold_result, content, status, created_at, storage_backend
        ) values (
            %(session_id)s, %(signal_id)s, %(signal_type)s, %(source)s, %(threshold_result)s, %(content)s::jsonb, %(status)s, %(created_at)s::timestamptz, %(storage_backend)s
        )
        on conflict (session_id) do update set
            signal_id = excluded.signal_id,
            signal_type = excluded.signal_type,
            source = excluded.source,
            threshold_result = excluded.threshold_result,
            content = excluded.content,
            status = excluded.status,
            created_at = excluded.created_at,
            storage_backend = excluded.storage_backend;
        """
        data = record.model_dump(mode="json")
        data["content"] = json.dumps(data["content"])
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(sql, data)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to upsert session record in Postgres: {exc}") from exc
        return record

    def get(self, session_id: str) -> SessionRecord | None:
        sql = """
        select session_id, signal_id, signal_type, source, threshold_result, content, status, created_at, storage_backend
        from session_records
        where session_id = %(session_id)s
        limit 1;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"session_id": session_id})
                    row = cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to fetch session record from Postgres: {exc}") from exc
        if row is None:
            return None
        return self._row_to_record(row)

    def list_recent(self, limit: int = 50) -> list[SessionRecord]:
        sql = """
        select session_id, signal_id, signal_type, source, threshold_result, content, status, created_at, storage_backend
        from session_records
        order by created_at desc
        limit %(limit)s;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"limit": limit})
                    rows = cur.fetchall()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to list session records from Postgres: {exc}") from exc
        return [self._row_to_record(row) for row in rows]

    def ping(self) -> dict[str, str]:
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute("select 1;")
                    cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Postgres session store health check failed: {exc}") from exc
        return {
            "status": "ok",
            "backend": self.backend_name,
            "dsn": self.dsn,
        }


def build_session_store(store_path: Path) -> SessionStore:
    backend = os.getenv("SESSION_ENGINE_STORE_BACKEND", "local_json").strip().lower()
    if backend == "postgres":
        dsn = os.getenv("SESSION_ENGINE_POSTGRES_DSN", "").strip()
        if not dsn:
            raise RuntimeError("SESSION_ENGINE_POSTGRES_DSN is required when SESSION_ENGINE_STORE_BACKEND=postgres")
        return PostgresSessionStore(dsn)
    return LocalJsonSessionStore(store_path)
