from typing import Any, Literal

from fastapi import FastAPI
from pydantic import BaseModel


class SessionStartInput(BaseModel):
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    content: dict[str, Any]


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
