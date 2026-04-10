import json
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


REPO_ROOT = Path(__file__).resolve().parents[3]
DATA_DIR = Path(__file__).resolve().parents[1] / "data"
STORE_PATH = DATA_DIR / "signals.json"

load_dotenv(REPO_ROOT / ".env")

HERALD_BASE_URL = os.getenv("HERALD_BASE_URL", "http://127.0.0.1:8001")
SESSION_ENGINE_BASE_URL = os.getenv("SESSION_ENGINE_BASE_URL", "http://127.0.0.1:8002")
EIDON_BASE_URL = os.getenv("EIDON_BASE_URL", "http://127.0.0.1:8003")


def ensure_store() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def load_signals() -> list[SignalRecord]:
    ensure_store()
    raw = STORE_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return []

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"Signal store is invalid JSON: {exc}") from exc

    if not isinstance(data, list):
        raise HTTPException(status_code=500, detail="Signal store must contain a JSON list.")

    return [SignalRecord.model_validate(item) for item in data]


def save_signals(records: list[SignalRecord]) -> None:
    ensure_store()
    payload = [record.model_dump() for record in records]
    STORE_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def build_signal_record(signal: SignalEventInput, storage_backend: str = "local_json") -> SignalRecord:
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


def upsert_signal(record: SignalRecord) -> SignalRecord:
    records = load_signals()

    updated = False
    for index, existing in enumerate(records):
        if existing.signal_id == record.signal_id:
            records[index] = record
            updated = True
            break

    if not updated:
        records.append(record)

    save_signals(records)
    return record


def get_signal(signal_id: str) -> SignalRecord | None:
    records = load_signals()
    for record in records:
        if record.signal_id == signal_id:
            return record
    return None


app = FastAPI(
    title="Eidonic Core Signal Gateway",
    version="0.2.2",
    description="Ingress service scaffold for the Eidonic Core with signal record persistence and full downstream chaining.",
)


@app.on_event("startup")
def startup() -> None:
    ensure_store()


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "signal-gateway",
    }


@app.get("/signals/{signal_id}")
def get_signal_by_id(signal_id: str) -> dict[str, object]:
    record = get_signal(signal_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Signal not found: {signal_id}")

    return {
        "status": "found",
        "service": "signal-gateway",
        "signal": record.model_dump(),
    }


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


@app.post("/signals/ingest")
def ingest_signal(signal: SignalEventInput) -> dict[str, Any]:
    saved_signal = upsert_signal(build_signal_record(signal))

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
