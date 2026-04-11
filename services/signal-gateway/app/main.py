import os
from pathlib import Path
from typing import Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from eidonic_schemas import (
    EidonOrchestrationInput,
    HeraldCheckInput,
    SessionStartInput,
    SignalEventInput,
    SignalRecord,
)

from app.store import SignalStore, build_signal_store


REPO_ROOT = Path(__file__).resolve().parents[3]
STORE_PATH = Path(__file__).resolve().parents[1] / "data" / "signals.json"

load_dotenv(REPO_ROOT / ".env")

HERALD_BASE_URL = os.getenv("HERALD_BASE_URL", "http://127.0.0.1:8001")
SESSION_ENGINE_BASE_URL = os.getenv("SESSION_ENGINE_BASE_URL", "http://127.0.0.1:8002")
EIDON_BASE_URL = os.getenv("EIDON_BASE_URL", "http://127.0.0.1:8003")

STORE: SignalStore = build_signal_store(STORE_PATH)


def build_signal_record(signal: SignalEventInput, storage_backend: str) -> SignalRecord:
    return SignalRecord(
        schema_version=signal.schema_version,
        signal_id=signal.signal_id,
        signal_type=signal.signal_type,
        source=signal.source,
        content=signal.content,
        created_at=signal.created_at,
        session_hint=signal.session_hint,
        sensitivity_hint=signal.sensitivity_hint,
        metadata=signal.metadata,
        status="accepted",
        storage_backend=storage_backend,
    )


def post_json(url: str, payload: dict[str, Any]) -> dict[str, Any]:
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.post(url, json=payload)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"Downstream call failed for {url}: {exc}") from exc


def derive_intent(signal: SignalEventInput) -> str:
    if signal.signal_type == "user_message":
        text = signal.content.get("text")
        if isinstance(text, str) and text.strip():
            return f"Respond to the user message: {text.strip()}"
        return "Respond to the user message."

    if signal.signal_type == "file_upload":
        return "Review the uploaded file and determine the next useful response."

    if signal.signal_type == "system_event":
        return "Interpret the system event and determine the next useful response."

    if signal.signal_type == "command":
        return "Execute or respond to the command in the current session context."

    return "Determine the next useful response."


app = FastAPI(
    title="Eidonic Core Signal Gateway",
    version="0.2.6",
    description="Ingress service scaffold for the Eidonic Core with a Postgres backend pilot.",
)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "service": "signal-gateway",
        "store": STORE.ping(),
    }


@app.get("/signals")
def list_signals(limit: int = 50) -> dict[str, object]:
    records = STORE.list_recent(limit=limit)
    return {
        "status": "found",
        "service": "signal-gateway",
        "count": len(records),
        "signals": [record.model_dump() for record in records],
    }


@app.get("/signals/{signal_id}")
def get_signal_by_id(signal_id: str) -> dict[str, object]:
    record = STORE.get(signal_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Signal not found: {signal_id}")
    return {
        "status": "found",
        "service": "signal-gateway",
        "signal": record.model_dump(),
    }


@app.post("/signals/ingest")
def ingest_signal(signal: SignalEventInput) -> dict[str, Any]:
    saved_signal = STORE.upsert(build_signal_record(signal, storage_backend=STORE.backend_name))

    herald_payload = HeraldCheckInput(
        signal_id=signal.signal_id,
        signal_type=signal.signal_type,
        source=signal.source,
        sensitivity_hint=signal.sensitivity_hint,
        content=signal.content,
    )

    herald_result = post_json(
        f"{HERALD_BASE_URL}/threshold/check",
        herald_payload.model_dump(),
    )

    response: dict[str, Any] = {
        "status": "accepted",
        "service": "signal-gateway",
        "received_signal_id": saved_signal.signal_id,
        "storage_backend": saved_signal.storage_backend,
        "message": "Signal accepted, persisted, and sent through the current downstream chain.",
        "herald_result": herald_result,
    }

    if herald_result.get("threshold_result") != "pass":
        response["session_result"] = None
        response["eidon_result"] = None
        response["derived_intent"] = None
        return response

    session_payload = SessionStartInput(
        signal_id=signal.signal_id,
        signal_type=signal.signal_type,
        source=signal.source,
        threshold_result=herald_result["threshold_result"],
        content=signal.content,
    )

    session_result = post_json(
        f"{SESSION_ENGINE_BASE_URL}/sessions/start",
        session_payload.model_dump(),
    )

    response["session_result"] = session_result

    if session_result.get("status") != "started":
        response["eidon_result"] = None
        response["derived_intent"] = None
        return response

    derived_intent = derive_intent(signal)

    eidon_payload = EidonOrchestrationInput(
        session_id=session_result["session_id"],
        signal_id=signal.signal_id,
        signal_type=signal.signal_type,
        source=signal.source,
        threshold_result=herald_result["threshold_result"],
        intent=derived_intent,
        content=signal.content,
    )

    eidon_result = post_json(
        f"{EIDON_BASE_URL}/orchestrate",
        eidon_payload.model_dump(),
    )

    response["derived_intent"] = derived_intent
    response["eidon_result"] = eidon_result
    return response
