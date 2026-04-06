from typing import Any, Literal

from fastapi import FastAPI
from pydantic import BaseModel


class HeraldCheckInput(BaseModel):
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    content: dict[str, Any]


app = FastAPI(
    title="Eidonic Core Herald Service",
    version="0.1.0",
    description="First thresholding service scaffold for the Eidonic Core.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "herald-service",
    }


@app.post("/threshold/check")
def threshold_check(payload: HeraldCheckInput) -> dict[str, Any]:
    return {
        "status": "reviewed",
        "service": "herald-service",
        "signal_id": payload.signal_id,
        "threshold_result": "pass",
        "message": "Herald scaffold reviewed the signal. Clarification, consent, and escalation logic are not implemented yet.",
    }
