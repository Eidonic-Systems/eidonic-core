from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from eidonic_schemas import HeraldCheckInput, ThresholdRecord

from app.store import LocalJsonThresholdStore, ThresholdStore


STORE_PATH = Path(__file__).resolve().parents[1] / "data" / "thresholds.json"
STORE: ThresholdStore = LocalJsonThresholdStore(STORE_PATH)


def build_threshold_record(payload: HeraldCheckInput, storage_backend: str) -> ThresholdRecord:
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


app = FastAPI(
    title="Eidonic Core Herald Service",
    version="0.2.1",
    description="Threshold review scaffold for the Eidonic Core with a store contract surface for threshold persistence.",
)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "service": "herald-service",
        "store": STORE.ping(),
    }


@app.get("/thresholds/{signal_id}")
def get_threshold_by_signal_id(signal_id: str) -> dict[str, object]:
    record = STORE.get(signal_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Threshold record not found for signal: {signal_id}")

    return {
        "status": "found",
        "service": "herald-service",
        "threshold": record.model_dump(),
    }


@app.post("/threshold/check")
def threshold_check(payload: HeraldCheckInput) -> dict[str, object]:
    record = build_threshold_record(payload, storage_backend=STORE.backend_name)
    saved = STORE.upsert(record)

    return {
        "status": "reviewed",
        "service": "herald-service",
        "threshold_id": saved.threshold_id,
        "signal_id": saved.signal_id,
        "threshold_result": saved.threshold_result,
        "storage_backend": saved.storage_backend,
        "message": saved.message,
    }
