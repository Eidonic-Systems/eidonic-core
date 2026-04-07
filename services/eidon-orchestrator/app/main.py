from typing import Any, Literal

from fastapi import FastAPI
from pydantic import BaseModel


class OrchestrateInput(BaseModel):
    session_id: str
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    content: dict[str, Any]


app = FastAPI(
    title="Eidonic Core Eidon Orchestrator",
    version="0.1.0",
    description="First orchestration service scaffold for the Eidonic Core.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "eidon-orchestrator",
    }


@app.post("/orchestrate")
def orchestrate(payload: OrchestrateInput) -> dict[str, Any]:
    return {
        "status": "orchestrated",
        "service": "eidon-orchestrator",
        "session_id": payload.session_id,
        "signal_id": payload.signal_id,
        "message": "Eidon scaffold orchestrated the request. Routing, tool use, memory access, and multi-organ weaving are not implemented yet.",
    }
