import json
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from eidonic_schemas import HeraldCheckInput, ThresholdRecord


DATA_DIR = Path(__file__).resolve().parents[1] / "data"
STORE_PATH = DATA_DIR / "thresholds.json"


def ensure_store() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def load_thresholds() -> list[ThresholdRecord]:
    ensure_store()
    raw = STORE_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return []

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"Threshold store is invalid JSON: {exc}") from exc

    if not isinstance(data, list):
        raise HTTPException(status_code=500, detail="Threshold store must contain a JSON list.")

    return [ThresholdRecord.model_validate(item) for item in data]


def save_thresholds(records: list[ThresholdRecord]) -> None:
    ensure_store()
    payload = [record.model_dump() for record in records]
    STORE_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def build_threshold_record(payload: HeraldCheckInput, storage_backend: str = "local_json") -> ThresholdRecord:
    threshold_result = "pass"
    message = "Herald scaffold reviewed the signal and persisted a threshold record. Clarification, consent, and escalation logic are not implemented yet."

    return ThresholdRecord(
        threshold_id=f"threshold-{payload.signal_id}",
        signal_id=payload.signal_id,
        signal_type=payload.signal_type,
        source=payload.source,
        sensitivity_hint=payload.sensitivity_hint,
        content=payload.content,
        threshold_result=threshold_result,
        status="reviewed",
        message=message,
        created_at=datetime.now(timezone.utc).isoformat(),
        storage_backend=storage_backend,
    )


def upsert_threshold(record: ThresholdRecord) -> ThresholdRecord:
    records = load_thresholds()

    updated = False
    for index, existing in enumerate(records):
        if existing.signal_id == record.signal_id:
            records[index] = record
            updated = True
            break

    if not updated:
        records.append(record)

    save_thresholds(records)
    return record


def get_threshold(signal_id: str) -> ThresholdRecord | None:
    records = load_thresholds()
    for record in records:
        if record.signal_id == signal_id:
            return record
    return None


app = FastAPI(
    title="Eidonic Core Herald Service",
    version="0.2.0",
    description="Threshold review scaffold for the Eidonic Core with local threshold persistence.",
)


@app.on_event("startup")
def startup() -> None:
    ensure_store()


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "herald-service",
    }


@app.get("/thresholds/{signal_id}")
def get_threshold_by_signal_id(signal_id: str) -> dict[str, object]:
    record = get_threshold(signal_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Threshold record not found for signal: {signal_id}")

    return {
        "status": "found",
        "service": "herald-service",
        "threshold": record.model_dump(),
    }


@app.post("/threshold/check")
def check_signal(payload: HeraldCheckInput) -> dict[str, object]:
    record = build_threshold_record(payload)
    saved = upsert_threshold(record)

    return {
        "status": "reviewed",
        "service": "herald-service",
        "threshold_id": saved.threshold_id,
        "signal_id": saved.signal_id,
        "threshold_result": saved.threshold_result,
        "storage_backend": saved.storage_backend,
        "message": saved.message,
    }

