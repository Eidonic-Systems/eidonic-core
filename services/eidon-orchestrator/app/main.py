import json
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException
from eidonic_schemas import EidonArtifactRecord, EidonOrchestrationInput


DATA_DIR = Path(__file__).resolve().parents[1] / "data"
STORE_PATH = DATA_DIR / "artifacts.json"


def ensure_store() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def load_artifacts() -> list[EidonArtifactRecord]:
    ensure_store()
    raw = STORE_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return []

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail=f"Artifact store is invalid JSON: {exc}") from exc

    if not isinstance(data, list):
        raise HTTPException(status_code=500, detail="Artifact store must contain a JSON list.")

    return [EidonArtifactRecord.model_validate(item) for item in data]


def save_artifacts(records: list[EidonArtifactRecord]) -> None:
    ensure_store()
    payload = [record.model_dump() for record in records]
    STORE_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def build_artifact(payload: EidonOrchestrationInput, storage_backend: str = "local_json") -> EidonArtifactRecord:
    artifact_id = f"artifact-{payload.session_id}"

    user_text = payload.content.get("text")
    if isinstance(user_text, str) and user_text.strip():
        response_text = f"Eidon received the intent: {payload.intent}"
    else:
        response_text = f"Eidon is prepared to act on the intent: {payload.intent}"

    return EidonArtifactRecord(
        artifact_id=artifact_id,
        session_id=payload.session_id,
        signal_id=payload.signal_id,
        signal_type=payload.signal_type,
        source=payload.source,
        threshold_result=payload.threshold_result,
        intent=payload.intent,
        content=payload.content,
        status="orchestrated",
        response_text=response_text,
        created_at=datetime.now(timezone.utc).isoformat(),
        storage_backend=storage_backend,
    )


def upsert_artifact(record: EidonArtifactRecord) -> EidonArtifactRecord:
    records = load_artifacts()

    updated = False
    for index, existing in enumerate(records):
        if existing.artifact_id == record.artifact_id:
            records[index] = record
            updated = True
            break

    if not updated:
        records.append(record)

    save_artifacts(records)
    return record


def get_artifact(artifact_id: str) -> EidonArtifactRecord | None:
    records = load_artifacts()
    for record in records:
        if record.artifact_id == artifact_id:
            return record
    return None


app = FastAPI(
    title="Eidonic Core Eidon Orchestrator",
    version="0.2.0",
    description="Orchestration service scaffold for the Eidonic Core with local artifact persistence.",
)


@app.on_event("startup")
def startup() -> None:
    ensure_store()


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "eidon-orchestrator",
    }


@app.get("/artifacts/{artifact_id}")
def get_artifact_by_id(artifact_id: str) -> dict[str, object]:
    record = get_artifact(artifact_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Artifact not found: {artifact_id}")

    return {
        "status": "found",
        "service": "eidon-orchestrator",
        "artifact": record.model_dump(),
    }


@app.post("/orchestrate")
def orchestrate(payload: EidonOrchestrationInput) -> dict[str, object]:
    artifact = build_artifact(payload)
    saved = upsert_artifact(artifact)

    return {
        "status": "orchestrated",
        "service": "eidon-orchestrator",
        "session_id": saved.session_id,
        "signal_id": saved.signal_id,
        "artifact_id": saved.artifact_id,
        "storage_backend": saved.storage_backend,
        "message": "Eidon scaffold orchestrated the request and persisted an artifact record.",
    }
