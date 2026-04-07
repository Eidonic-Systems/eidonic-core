from typing import Any

from fastapi import FastAPI
from eidonic_schemas import EidonOrchestrationInput


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
def orchestrate(payload: EidonOrchestrationInput) -> dict[str, Any]:
    return {
        "status": "orchestrated",
        "service": "eidon-orchestrator",
        "session_id": payload.session_id,
        "signal_id": payload.signal_id,
        "message": "Eidon scaffold orchestrated the request. Tool selection, memory use, and response generation are not implemented yet.",
    }
