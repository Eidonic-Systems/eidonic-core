from typing import Any

from fastapi import FastAPI
from eidonic_schemas import SessionStartInput


app = FastAPI(
    title="Eidonic Core Session Engine",
    version="0.1.0",
    description="First session binding service scaffold for the Eidonic Core.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "session-engine",
    }


@app.post("/sessions/start")
def start_session(payload: SessionStartInput) -> dict[str, Any]:
    session_id = f"session-{payload.signal_id}"

    return {
        "status": "started",
        "service": "session-engine",
        "session_id": session_id,
        "signal_id": payload.signal_id,
        "message": "Session scaffold started a session. Persistence, stage tracking, and closure logic are not implemented yet.",
    }
