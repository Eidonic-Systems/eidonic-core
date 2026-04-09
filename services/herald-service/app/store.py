import json
from pathlib import Path
from typing import Protocol

from fastapi import HTTPException
from eidonic_schemas import ThresholdRecord


class ThresholdStore(Protocol):
    @property
    def backend_name(self) -> str: ...

    def upsert(self, record: ThresholdRecord) -> ThresholdRecord: ...

    def get(self, signal_id: str) -> ThresholdRecord | None: ...

    def list(self) -> list[ThresholdRecord]: ...

    def ping(self) -> dict[str, str]: ...


class LocalJsonThresholdStore:
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

    def _load_records(self) -> list[ThresholdRecord]:
        self._ensure_store()
        raw = self.store_path.read_text(encoding="utf-8").strip()
        if not raw:
            return []

        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise HTTPException(status_code=500, detail=f"Threshold store is invalid JSON: {exc}") from exc

        if not isinstance(data, list):
            raise HTTPException(status_code=500, detail="Threshold store must contain a JSON list.")

        return [ThresholdRecord.model_validate(item) for item in data]

    def _save_records(self, records: list[ThresholdRecord]) -> None:
        self._ensure_store()
        payload = [record.model_dump() for record in records]
        self.store_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def upsert(self, record: ThresholdRecord) -> ThresholdRecord:
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

    def get(self, signal_id: str) -> ThresholdRecord | None:
        records = self._load_records()
        for record in records:
            if record.signal_id == signal_id:
                return record
        return None

    def list(self) -> list[ThresholdRecord]:
        return self._load_records()

    def ping(self) -> dict[str, str]:
        self._ensure_store()
        return {
            "status": "ok",
            "backend": self.backend_name,
            "store_path": str(self.store_path),
        }
