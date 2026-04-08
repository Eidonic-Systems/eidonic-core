import json
from pathlib import Path
from typing import Protocol

from fastapi import HTTPException
from eidonic_schemas import SessionRecord


class SessionStore(Protocol):
    @property
    def backend_name(self) -> str:
        ...

    def upsert(self, record: SessionRecord) -> SessionRecord:
        ...

    def get(self, session_id: str) -> SessionRecord | None:
        ...

    def list_recent(self, limit: int = 50) -> list[SessionRecord]:
        ...

    def ping(self) -> dict[str, str]:
        ...


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
