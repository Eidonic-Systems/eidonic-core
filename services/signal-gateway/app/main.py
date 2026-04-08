import os
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException

from eidonic_schemas import SignalEventInput

HERALD_BASE_URL = os.getenv("HERALD_BASE_URL", "http://127.0.0.1:8001")

app = FastAPI(
    title="Eidonic Core Signal Gateway",
    version="0.2.0",
    description="Ingress service scaffold for the Eidonic Core with first downstream handoff to Herald.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "signal-gateway",
        "herald_base_url": HERALD_BASE_URL,
    }


@app.post("/signals/ingest")
def ingest_signal(signal: SignalEventInput) -> dict[str, Any]:
    herald_payload = {
        "signal_id": signal.signal_id,
        "signal_type": signal.signal_type,
        "source": signal.source,
        "sensitivity_hint": signal.sensitivity_hint,
        "content": signal.content,
    }

    try:
        with httpx.Client(timeout=10.0) as client:
            herald_response = client.post(
                f"{HERALD_BASE_URL}/threshold/check",
                json=herald_payload,
            )
            herald_response.raise_for_status()
            herald_result = herald_response.json()
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to call herald-service at {HERALD_BASE_URL}: {exc}",
        ) from exc

    return {
        "status": "accepted",
        "service": "signal-gateway",
        "received_signal_id": signal.signal_id,
        "herald_result": herald_result,
        "message": "Signal accepted and forwarded to Herald. Session binding and orchestration are not implemented yet.",
    }
