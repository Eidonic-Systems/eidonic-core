from typing import Any

from fastapi import FastAPI
from eidonic_schemas import SignalEventInput


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
