import os
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from eidonic_schemas import SignalEventInput

HERALD_SERVICE_BASE_URL = os.getenv("HERALD_SERVICE_BASE_URL", "http://127.0.0.1:8001")
SESSION_ENGINE_BASE_URL = os.getenv("SESSION_ENGINE_BASE_URL", "http://127.0.0.1:8002")

app = FastAPI(
    title="Eidonic Core Signal Gateway",
    version="0.2.0",
    description="Ingress service scaffold for the Eidonic Core with first downstream threshold and session handoff.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "signal-gateway",
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
        herald_response = httpx.post(
            f"{HERALD_SERVICE_BASE_URL}/threshold/check",
            json=herald_payload,
            timeout=10.0,
        )
        herald_response.raise_for_status()
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to reach herald-service: {exc}",
        ) from exc

    herald_result = herald_response.json()

    response: dict[str, Any] = {
        "status": "accepted",
        "service": "signal-gateway",
        "received_signal_id": signal.signal_id,
        "herald_result": herald_result,
        "message": "Signal accepted by gateway and reviewed by Herald.",
    }

    threshold_result = herald_result.get("threshold_result")
    if threshold_result == "pass":
        session_payload = {
            "signal_id": signal.signal_id,
            "signal_type": signal.signal_type,
            "source": signal.source,
            "threshold_result": threshold_result,
            "content": signal.content,
        }

        try:
            session_response = httpx.post(
                f"{SESSION_ENGINE_BASE_URL}/sessions/start",
                json=session_payload,
                timeout=10.0,
            )
            session_response.raise_for_status()
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Failed to reach session-engine: {exc}",
            ) from exc

        response["session_result"] = session_response.json()
        response["message"] = (
            "Signal accepted by gateway, reviewed by Herald, and passed to Session Engine."
        )
    else:
        response["message"] = (
            "Signal accepted by gateway and reviewed by Herald. Session start was skipped."
        )

    return response
