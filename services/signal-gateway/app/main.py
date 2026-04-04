from typing import Any, Literal

from fastapi import FastAPI
from pydantic import BaseModel, Field
from datetime import datetime


class SignalEventInput(BaseModel):
    schema_version: Literal["1.0.0"]
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    content: dict[str, Any]
    created_at: datetime
    session_hint: str | None = None
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


app = FastAPI(
    title="Eidonic Core Signal Gateway",
    version="0.1.0",
    description="First ingress service scaffold for the Eidonic Core.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "signal-gateway",
    }


@app.post("/signals/ingest")
def ingest_signal(signal: SignalEventInput) -> dict[str, Any]:
    return {
        "status": "accepted",
        "service": "signal-gateway",
        "received_signal_id": signal.signal_id,
        "message": "Signal accepted by scaffold. Thresholding and session binding are not implemented yet.",
    }
