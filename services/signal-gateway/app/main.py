import os
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException

from eidonic_schemas import SignalEventInput


HERALD_BASE_URL = os.getenv("HERALD_BASE_URL", "http://127.0.0.1:8001")
SESSION_ENGINE_BASE_URL = os.getenv("SESSION_ENGINE_BASE_URL", "http://127.0.0.1:8002")
EIDON_BASE_URL = os.getenv("EIDON_BASE_URL", "http://127.0.0.1:8003")


app = FastAPI(
    title="Eidonic Core Signal Gateway",
    version="0.1.0",
    description="Ingress service scaffold for the Eidonic Core with downstream chaining.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "signal-gateway",
    }


def post_json(url: str, payload: dict[str, Any]) -> dict[str, Any]:
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.post(url, json=payload)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Downstream call failed for {url}: {exc}") from exc


@app.post("/signals/ingest")
def ingest_signal(signal: SignalEventInput) -> dict[str, Any]:
    herald_payload = {
        "signal_id": signal.signal_id,
        "signal_type": signal.signal_type,
        "source": signal.source,
        "sensitivity_hint": signal.sensitivity_hint,
        "content": signal.content,
    }

    herald_result = post_json(f"{HERALD_BASE_URL}/threshold/check", herald_payload)

    response: dict[str, Any] = {
        "status": "accepted",
        "service": "signal-gateway",
        "received_signal_id": signal.signal_id,
        "message": "Signal accepted and sent through the current downstream chain.",
        "herald_result": herald_result,
    }

    if herald_result.get("threshold_result") != "pass":
        response["session_result"] = None
        response["eidon_result"] = None
        return response

    session_payload = {
        "signal_id": signal.signal_id,
        "signal_type": signal.signal_type,
        "source": signal.source,
        "threshold_result": herald_result["threshold_result"],
        "content": signal.content,
    }

    session_result = post_json(f"{SESSION_ENGINE_BASE_URL}/sessions/start", session_payload)
    response["session_result"] = session_result

    if session_result.get("status") != "started":
        response["eidon_result"] = None
        return response

    eidon_payload = {
        "session_id": session_result["session_id"],
        "signal_id": signal.signal_id,
        "signal_type": signal.signal_type,
        "source": signal.source,
        "threshold_result": herald_result["threshold_result"],
        "intent": "Respond to the user's first message",
        "content": signal.content,
    }

    eidon_result = post_json(f"{EIDON_BASE_URL}/orchestrate", eidon_payload)
    response["eidon_result"] = eidon_result

    return response
