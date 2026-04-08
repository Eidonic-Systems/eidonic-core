import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException
from eidonic_schemas import SessionStartInput


DATA_DIR = Path(__file__).resolve().parents[1] / "data"
STORE_PATH = DATA_DIR / "sessions.json"


def ensure_store() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def load_sessions() -> list[dict[str, Any]]:
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

    return data


def save_sessions(sessions: list[dict[str, Any]]) -> None:
    ensure_store()
    STORE_PATH.write_text(json.dumps(sessions, indent=2), encoding="utf-8")


def upsert_session(record: dict[str, Any]) -> dict[str, Any]:
    sessions = load_sessions()

    updated = False
    for index, existing in enumerate(sessions):
        if existing.get("session_id") == record["session_id"]:
            sessions[index] = record
            updated = True
            break

    if not updated:
        sessions.append(record)

    save_sessions(sessions)
    return record


def get_session_record(session_id: str) -> dict[str, Any] | None:
    sessions = load_sessions()
    for record in sessions:
        if record.get("session_id") == session_id:
            return record
    return None


app = FastAPI(
    title="Eidonic Core Session Engine",
    version="0.2.0",
    description="Session binding service scaffold for the Eidonic Core with local JSON persistence.",
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
def get_session(session_id: str) -> dict[str, Any]:
    record = get_session_record(session_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")

    return {
        "status": "found",
        "service": "session-engine",
        "session": record,
    }


@app.post("/sessions/start")
def start_session(payload: SessionStartInput) -> dict[str, Any]:
    session_id = f"session-{payload.signal_id}"

    record = {
        "session_id": session_id,
        "signal_id": payload.signal_id,
        "signal_type": payload.signal_type,
        "source": payload.source,
        "threshold_result": payload.threshold_result,
        "content": payload.content,
        "status": "started",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "storage_backend": "local_json"
    }

    saved = upsert_session(record)

    return {
        "status": "started",
        "service": "session-engine",
        "session_id": saved["session_id"],
        "signal_id": saved["signal_id"],
        "storage_backend": saved["storage_backend"],
        "message": "Session started and persisted to the local JSON store.",
    }
