import json
import os
from datetime import datetime
from pathlib import Path
from typing import Protocol

import psycopg
from fastapi import HTTPException
from eidonic_schemas import ArtifactLineageRecord, EidonArtifactRecord


class ArtifactStore(Protocol):
    @property
    def backend_name(self) -> str: ...

    def upsert(self, record: EidonArtifactRecord) -> EidonArtifactRecord: ...

    def get(self, artifact_id: str) -> EidonArtifactRecord | None: ...

    def list_recent(self, limit: int = 50) -> list[EidonArtifactRecord]: ...

    def ping(self) -> dict[str, str]: ...


class ArtifactLineageStore(Protocol):
    @property
    def backend_name(self) -> str: ...

    def upsert(self, record: ArtifactLineageRecord) -> ArtifactLineageRecord: ...

    def get_by_artifact_id(self, artifact_id: str) -> ArtifactLineageRecord | None: ...

    def list_recent(self, limit: int = 50) -> list[ArtifactLineageRecord]: ...

    def ping(self) -> dict[str, str]: ...


class LocalJsonArtifactStore:
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

    def _load_records(self) -> list[EidonArtifactRecord]:
        self._ensure_store()
        raw = self.store_path.read_text(encoding="utf-8").strip()
        if not raw:
            return []
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=500, detail=f"Artifact store is invalid JSON: {exc}") from exc
        if not isinstance(data, list):
            raise HTTPException(status_code=500, detail="Artifact store must contain a JSON list.")

        records: list[EidonArtifactRecord] = []
        for item in data:
            if isinstance(item, dict):
                item.setdefault("provider_backend", "unknown")
                item.setdefault("provider_model", "unknown")
                item.setdefault("provider_status", "succeeded")
                item.setdefault("provider_route_mode", "")
                item.setdefault("provider_route_reason", "")
                item.setdefault("provider_error_code", None)
                item.setdefault("provider_error_message", None)
            records.append(EidonArtifactRecord.model_validate(item))
        return records

    def _save_records(self, records: list[EidonArtifactRecord]) -> None:
        self._ensure_store()
        payload = [record.model_dump() for record in records]
        self.store_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def upsert(self, record: EidonArtifactRecord) -> EidonArtifactRecord:
        records = self._load_records()
        updated = False
        for index, existing in enumerate(records):
            if existing.artifact_id == record.artifact_id:
                records[index] = record
                updated = True
                break
        if not updated:
            records.append(record)
        self._save_records(records)
        return record

    def get(self, artifact_id: str) -> EidonArtifactRecord | None:
        records = self._load_records()
        for record in records:
            if record.artifact_id == artifact_id:
                return record
        return None

    def list_recent(self, limit: int = 50) -> list[EidonArtifactRecord]:
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


class LocalJsonArtifactLineageStore:
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

    def _load_records(self) -> list[ArtifactLineageRecord]:
        self._ensure_store()
        raw = self.store_path.read_text(encoding="utf-8").strip()
        if not raw:
            return []
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=500, detail=f"Lineage store is invalid JSON: {exc}") from exc
        if not isinstance(data, list):
            raise HTTPException(status_code=500, detail="Lineage store must contain a JSON list.")

        records: list[ArtifactLineageRecord] = []
        for item in data:
            if isinstance(item, dict):
                item.setdefault("artifact_provider_backend", "unknown")
                item.setdefault("artifact_provider_model", "unknown")
                item.setdefault("artifact_provider_status", "succeeded")
                item.setdefault("artifact_provider_route_mode", "")
                item.setdefault("artifact_provider_route_reason", "")
                item.setdefault("artifact_provider_error_code", None)
                item.setdefault("artifact_provider_error_message", None)
            records.append(ArtifactLineageRecord.model_validate(item))
        return records

    def _save_records(self, records: list[ArtifactLineageRecord]) -> None:
        self._ensure_store()
        payload = [record.model_dump() for record in records]
        self.store_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def upsert(self, record: ArtifactLineageRecord) -> ArtifactLineageRecord:
        records = self._load_records()
        updated = False
        for index, existing in enumerate(records):
            if existing.lineage_id == record.lineage_id:
                records[index] = record
                updated = True
                break
        if not updated:
            records.append(record)
        self._save_records(records)
        return record

    def get_by_artifact_id(self, artifact_id: str) -> ArtifactLineageRecord | None:
        records = self._load_records()
        for record in records:
            if record.artifact_id == artifact_id:
                return record
        return None

    def list_recent(self, limit: int = 50) -> list[ArtifactLineageRecord]:
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


class PostgresArtifactStore:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self._ensure_schema()

    @property
    def backend_name(self) -> str:
        return "postgres"

    def _connect(self):
        return psycopg.connect(self.dsn)

    def _row_to_record(self, row: dict) -> EidonArtifactRecord:
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

        return EidonArtifactRecord.model_validate(data)

    def _ensure_schema(self) -> None:
        ddl = """
        create table if not exists artifact_records (
            artifact_id text primary key,
            session_id text not null,
            signal_id text not null,
            signal_type text not null,
            source text not null,
            threshold_result text not null,
            intent text not null,
            content jsonb not null,
            status text not null,
            response_text text not null,
            created_at timestamptz not null,
            storage_backend text not null,
            provider_backend text not null default 'unknown',
            provider_model text not null default 'unknown',
            provider_status text not null default 'succeeded',
            provider_route_mode text not null default '',
            provider_route_reason text not null default '',
            provider_error_code text null,
            provider_error_message text null
        );
        create index if not exists idx_artifact_records_created_at on artifact_records (created_at desc);
        alter table artifact_records add column if not exists provider_backend text not null default 'unknown';
        alter table artifact_records add column if not exists provider_model text not null default 'unknown';
        alter table artifact_records add column if not exists provider_status text not null default 'succeeded';
        alter table artifact_records add column if not exists provider_route_mode text not null default '';
        alter table artifact_records add column if not exists provider_route_reason text not null default '';
        alter table artifact_records add column if not exists provider_error_code text null;
        alter table artifact_records add column if not exists provider_error_message text null;
        """
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(ddl)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to initialize Postgres artifact store: {exc}") from exc

    def upsert(self, record: EidonArtifactRecord) -> EidonArtifactRecord:
        sql = """
        insert into artifact_records (
            artifact_id, session_id, signal_id, signal_type, source, threshold_result, intent, content, status, response_text, created_at, storage_backend, provider_backend, provider_model, provider_status, provider_route_mode, provider_route_reason, provider_error_code, provider_error_message
        ) values (
            %(artifact_id)s, %(session_id)s, %(signal_id)s, %(signal_type)s, %(source)s, %(threshold_result)s, %(intent)s, %(content)s::jsonb, %(status)s, %(response_text)s, %(created_at)s::timestamptz, %(storage_backend)s, %(provider_backend)s, %(provider_model)s, %(provider_status)s, %(provider_route_mode)s, %(provider_route_reason)s, %(provider_error_code)s, %(provider_error_message)s
        )
        on conflict (artifact_id) do update set
            session_id = excluded.session_id,
            signal_id = excluded.signal_id,
            signal_type = excluded.signal_type,
            source = excluded.source,
            threshold_result = excluded.threshold_result,
            intent = excluded.intent,
            content = excluded.content,
            status = excluded.status,
            response_text = excluded.response_text,
            created_at = excluded.created_at,
            storage_backend = excluded.storage_backend,
            provider_backend = excluded.provider_backend,
            provider_model = excluded.provider_model,
            provider_status = excluded.provider_status,
            provider_route_mode = excluded.provider_route_mode,
            provider_route_reason = excluded.provider_route_reason,
            provider_error_code = excluded.provider_error_code,
            provider_error_message = excluded.provider_error_message;
        """
        data = record.model_dump(mode="json")
        data["content"] = json.dumps(data["content"])
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(sql, data)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to upsert artifact record in Postgres: {exc}") from exc
        return record

    def get(self, artifact_id: str) -> EidonArtifactRecord | None:
        sql = """
        select artifact_id, session_id, signal_id, signal_type, source, threshold_result, intent, content, status, response_text, created_at, storage_backend, provider_backend, provider_model, provider_status, provider_route_mode, provider_route_reason, provider_error_code, provider_error_message
        from artifact_records
        where artifact_id = %(artifact_id)s
        limit 1;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"artifact_id": artifact_id})
                    row = cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to fetch artifact record from Postgres: {exc}") from exc
        if row is None:
            return None
        return self._row_to_record(row)

    def list_recent(self, limit: int = 50) -> list[EidonArtifactRecord]:
        sql = """
        select artifact_id, session_id, signal_id, signal_type, source, threshold_result, intent, content, status, response_text, created_at, storage_backend, provider_backend, provider_model, provider_status, provider_route_mode, provider_route_reason, provider_error_code, provider_error_message
        from artifact_records
        order by created_at desc
        limit %(limit)s;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"limit": limit})
                    rows = cur.fetchall()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to list artifact records from Postgres: {exc}") from exc
        return [self._row_to_record(row) for row in rows]

    def ping(self) -> dict[str, str]:
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute("select 1;")
                    cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Postgres artifact store health check failed: {exc}") from exc
        return {
            "status": "ok",
            "backend": self.backend_name,
            "dsn": self.dsn,
        }


class PostgresArtifactLineageStore:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self._ensure_schema()

    @property
    def backend_name(self) -> str:
        return "postgres"

    def _connect(self):
        return psycopg.connect(self.dsn)

    def _row_to_record(self, row: dict) -> ArtifactLineageRecord:
        data = dict(row)
        created_at = data.get("created_at")
        if isinstance(created_at, datetime):
            data["created_at"] = created_at.isoformat()
        return ArtifactLineageRecord.model_validate(data)

    def _ensure_schema(self) -> None:
        ddl = """
        create table if not exists artifact_lineage_records (
            lineage_id text primary key,
            artifact_id text not null unique,
            session_id text not null,
            signal_id text not null,
            signal_type text not null,
            source text not null,
            threshold_result text not null,
            artifact_status text not null,
            artifact_storage_backend text not null,
            artifact_provider_backend text not null default 'unknown',
            artifact_provider_model text not null default 'unknown',
            artifact_provider_status text not null default 'succeeded',
            artifact_provider_route_mode text not null default '',
            artifact_provider_route_reason text not null default '',
            artifact_provider_error_code text null,
            artifact_provider_error_message text null,
            artifact_kind text not null,
            created_at timestamptz not null
        );
        create index if not exists idx_artifact_lineage_records_created_at on artifact_lineage_records (created_at desc);
        alter table artifact_lineage_records add column if not exists artifact_provider_backend text not null default 'unknown';
        alter table artifact_lineage_records add column if not exists artifact_provider_model text not null default 'unknown';
        alter table artifact_lineage_records add column if not exists artifact_provider_status text not null default 'succeeded';
        alter table artifact_lineage_records add column if not exists artifact_provider_route_mode text not null default '';
        alter table artifact_lineage_records add column if not exists artifact_provider_route_reason text not null default '';
        alter table artifact_lineage_records add column if not exists artifact_provider_error_code text null;
        alter table artifact_lineage_records add column if not exists artifact_provider_error_message text null;
        """
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(ddl)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to initialize Postgres lineage store: {exc}") from exc

    def upsert(self, record: ArtifactLineageRecord) -> ArtifactLineageRecord:
        sql = """
        insert into artifact_lineage_records (
            lineage_id, artifact_id, session_id, signal_id, signal_type, source, threshold_result, artifact_status, artifact_storage_backend, artifact_provider_backend, artifact_provider_model, artifact_provider_status, artifact_provider_route_mode, artifact_provider_route_reason, artifact_provider_error_code, artifact_provider_error_message, artifact_kind, created_at
        ) values (
            %(lineage_id)s, %(artifact_id)s, %(session_id)s, %(signal_id)s, %(signal_type)s, %(source)s, %(threshold_result)s, %(artifact_status)s, %(artifact_storage_backend)s, %(artifact_provider_backend)s, %(artifact_provider_model)s, %(artifact_provider_status)s, %(artifact_provider_route_mode)s, %(artifact_provider_route_reason)s, %(artifact_provider_error_code)s, %(artifact_provider_error_message)s, %(artifact_kind)s, %(created_at)s::timestamptz
        )
        on conflict (lineage_id) do update set
            artifact_id = excluded.artifact_id,
            session_id = excluded.session_id,
            signal_id = excluded.signal_id,
            signal_type = excluded.signal_type,
            source = excluded.source,
            threshold_result = excluded.threshold_result,
            artifact_status = excluded.artifact_status,
            artifact_storage_backend = excluded.artifact_storage_backend,
            artifact_provider_backend = excluded.artifact_provider_backend,
            artifact_provider_model = excluded.artifact_provider_model,
            artifact_provider_status = excluded.artifact_provider_status,
            artifact_provider_route_mode = excluded.artifact_provider_route_mode,
            artifact_provider_route_reason = excluded.artifact_provider_route_reason,
            artifact_provider_error_code = excluded.artifact_provider_error_code,
            artifact_provider_error_message = excluded.artifact_provider_error_message,
            artifact_kind = excluded.artifact_kind,
            created_at = excluded.created_at;
        """
        data = record.model_dump(mode="json")
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(sql, data)
                conn.commit()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to upsert lineage record in Postgres: {exc}") from exc
        return record

    def get_by_artifact_id(self, artifact_id: str) -> ArtifactLineageRecord | None:
        sql = """
        select lineage_id, artifact_id, session_id, signal_id, signal_type, source, threshold_result, artifact_status, artifact_storage_backend, artifact_provider_backend, artifact_provider_model, artifact_provider_status, artifact_provider_route_mode, artifact_provider_route_reason, artifact_provider_error_code, artifact_provider_error_message, artifact_kind, created_at
        from artifact_lineage_records
        where artifact_id = %(artifact_id)s
        limit 1;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"artifact_id": artifact_id})
                    row = cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to fetch lineage record from Postgres: {exc}") from exc
        if row is None:
            return None
        return self._row_to_record(row)

    def list_recent(self, limit: int = 50) -> list[ArtifactLineageRecord]:
        sql = """
        select lineage_id, artifact_id, session_id, signal_id, signal_type, source, threshold_result, artifact_status, artifact_storage_backend, artifact_provider_backend, artifact_provider_model, artifact_provider_status, artifact_provider_route_mode, artifact_provider_route_reason, artifact_provider_error_code, artifact_provider_error_message, artifact_kind, created_at
        from artifact_lineage_records
        order by created_at desc
        limit %(limit)s;
        """
        try:
            with self._connect() as conn:
                with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
                    cur.execute(sql, {"limit": limit})
                    rows = cur.fetchall()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Failed to list lineage records from Postgres: {exc}") from exc
        return [self._row_to_record(row) for row in rows]

    def ping(self) -> dict[str, str]:
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute("select 1;")
                    cur.fetchone()
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Postgres lineage store health check failed: {exc}") from exc
        return {
            "status": "ok",
            "backend": self.backend_name,
            "dsn": self.dsn,
        }


def build_artifact_store(store_path: Path) -> ArtifactStore:
    backend = os.getenv("ORCHESTRATOR_STORE_BACKEND", "local_json").strip().lower()
    if backend == "postgres":
        dsn = os.getenv("ORCHESTRATOR_POSTGRES_DSN", "").strip()
        if not dsn:
            raise RuntimeError("ORCHESTRATOR_POSTGRES_DSN is required when ORCHESTRATOR_STORE_BACKEND=postgres")
        return PostgresArtifactStore(dsn)
    return LocalJsonArtifactStore(store_path)


def build_lineage_store(store_path: Path) -> ArtifactLineageStore:
    backend = os.getenv("ORCHESTRATOR_STORE_BACKEND", "local_json").strip().lower()
    if backend == "postgres":
        dsn = os.getenv("ORCHESTRATOR_POSTGRES_DSN", "").strip()
        if not dsn:
            raise RuntimeError("ORCHESTRATOR_POSTGRES_DSN is required when ORCHESTRATOR_STORE_BACKEND=postgres")
        return PostgresArtifactLineageStore(dsn)
    return LocalJsonArtifactLineageStore(store_path)
