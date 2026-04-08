from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from eidonic_schemas import SessionRecord, SessionStartInput

from app.store import LocalJsonSessionStore, SessionStore


STORE_PATH = Path(__file__).resolve().parents[1] / "data" / "sessions.json"
STORE: SessionStore = LocalJsonSessionStore(STORE_PATH)


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


app = FastAPI(
    title="Eidonic Core Session Engine",
    version="0.2.2",
    description="Session binding service scaffold for the Eidonic Core with a session store adapter boundary.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "session-engine",
    }


@app.get("/sessions/{session_id}")
def get_session(session_id: str) -> dict[str, object]:
    record = STORE.get(session_id)
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
    saved = STORE.upsert(record)

    return {
        "status": "started",
        "service": "session-engine",
        "session_id": saved.session_id,
        "signal_id": saved.signal_id,
        "storage_backend": saved.storage_backend,
        "message": "Session started and persisted through the session store adapter.",
    }
