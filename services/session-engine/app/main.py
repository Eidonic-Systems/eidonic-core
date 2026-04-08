import json
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from eidonic_schemas import SessionRecord, SessionStartInput


DATA_DIR = Path(__file__).resolve().parents[1] / "data"
STORE_PATH = DATA_DIR / "sessions.json"


def ensure_store() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def load_session_records() -> list[SessionRecord]:
    ensure_store()
    raw = STORE_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return []

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"Session store is invalid JSON: {exc}") from exc

    if not isinstance(data, list):
        raise HTTPException(status_code=500, detail="Session store must contain a JSON list.")

    return [SessionRecord.model_validate(item) for item in data]


def save_session_records(records: list[SessionRecord]) -> None:
    ensure_store()
    payload = [record.model_dump() for record in records]
    STORE_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def build_session_record(payload: SessionStartInput, storage_backend: str = "local_json") -> SessionRecord:
    return SessionRecord(
        session_id=f"session-{payload.signal_id}",
        signal_id=payload.signal_id,
        signal_type=payload.signal_type,
        source=payload.source,
        threshold_result=payload.threshold_result,
        content=payload.content,
        status="started",
        created_at=datetime.now(timezone.utc).isoformat(),
        storage_backend=storage_backend,
    )


def upsert_session_record(record: SessionRecord) -> SessionRecord:
    records = load_session_records()

    updated = False
    for index, existing in enumerate(records):
        if existing.session_id == record.session_id:
            records[index] = record
            updated = True
            break

    if not updated:
        records.append(record)

    save_session_records(records)
    return record


def get_session_record(session_id: str) -> SessionRecord | None:
    records = load_session_records()
    for record in records:
        if record.session_id == session_id:
            return record
    return None


app = FastAPI(
    title="Eidonic Core Session Engine",
    version="0.2.1",
    description="Session binding service scaffold for the Eidonic Core with a session record contract.",
)


@app.on_event("startup")
def startup() -> None:
    ensure_store()


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "session-engine",
    }


@app.get("/sessions/{session_id}")
def get_session(session_id: str) -> dict[str, object]:
    record = get_session_record(session_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")

    return {
        "status": "found",
        "service": "session-engine",
        "session": record.model_dump(),
    }


@app.post("/sessions/start")
def start_session(payload: SessionStartInput) -> dict[str, object]:
    record = build_session_record(payload)
    saved = upsert_session_record(record)

    return {
        "status": "started",
        "service": "session-engine",
        "session_id": saved.session_id,
        "signal_id": saved.signal_id,
        "storage_backend": saved.storage_backend,
        "message": "Session started and persisted through the session record contract.",
    }
