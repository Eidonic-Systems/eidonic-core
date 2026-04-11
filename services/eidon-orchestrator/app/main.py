from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from eidonic_schemas import ArtifactLineageRecord, EidonArtifactRecord, EidonOrchestrationInput

from app.provider import ModelProvider, ModelProviderError, build_model_provider
from app.store import (
    ArtifactLineageStore,
    ArtifactStore,
    build_artifact_store,
    build_lineage_store,
)


REPO_ROOT = Path(__file__).resolve().parents[3]
DATA_DIR = Path(__file__).resolve().parents[1] / "data"
ARTIFACT_STORE_PATH = DATA_DIR / "artifacts.json"
LINEAGE_STORE_PATH = DATA_DIR / "lineage.json"

load_dotenv(REPO_ROOT / ".env")

ARTIFACT_STORE: ArtifactStore = build_artifact_store(ARTIFACT_STORE_PATH)
LINEAGE_STORE: ArtifactLineageStore = build_lineage_store(LINEAGE_STORE_PATH)
PROVIDER: ModelProvider = build_model_provider()


def build_artifact(
    payload: EidonOrchestrationInput,
    storage_backend: str,
    provider_backend: str,
    provider_model: str,
    status: str,
    response_text: str,
    provider_status: str,
    provider_error_code: str | None = None,
    provider_error_message: str | None = None,
) -> EidonArtifactRecord:
    artifact_id = f"artifact-{payload.session_id}"

    return EidonArtifactRecord(
        artifact_id=artifact_id,
        session_id=payload.session_id,
        signal_id=payload.signal_id,
        signal_type=payload.signal_type,
        source=payload.source,
        threshold_result=payload.threshold_result,
        intent=payload.intent,
        content=payload.content,
        status=status,
        response_text=response_text,
        created_at=datetime.now(timezone.utc).isoformat(),
        storage_backend=storage_backend,
        provider_backend=provider_backend,
        provider_model=provider_model,
        provider_status=provider_status,
        provider_error_code=provider_error_code,
        provider_error_message=provider_error_message,
    )


def build_lineage_record(artifact: EidonArtifactRecord) -> ArtifactLineageRecord:
    return ArtifactLineageRecord(
        lineage_id=f"lineage-{artifact.artifact_id}",
        artifact_id=artifact.artifact_id,
        session_id=artifact.session_id,
        signal_id=artifact.signal_id,
        signal_type=artifact.signal_type,
        source=artifact.source,
        threshold_result=artifact.threshold_result,
        artifact_status=artifact.status,
        artifact_storage_backend=artifact.storage_backend,
        artifact_provider_backend=artifact.provider_backend,
        artifact_provider_model=artifact.provider_model,
        artifact_provider_status=artifact.provider_status,
        artifact_provider_error_code=artifact.provider_error_code,
        artifact_provider_error_message=artifact.provider_error_message,
        artifact_kind="eidon_orchestration",
        created_at=datetime.now(timezone.utc).isoformat(),
    )


app = FastAPI(
    title="Eidonic Core Eidon Orchestrator",
    version="0.3.0",
    description="Orchestration service scaffold for the Eidonic Core with provider warmup and readiness surfaces.",
)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "service": "eidon-orchestrator",
        "artifact_store": ARTIFACT_STORE.ping(),
        "lineage_store": LINEAGE_STORE.ping(),
        "provider": PROVIDER.ping(),
    }


@app.post("/provider/warm")
def warm_provider() -> dict[str, object]:
    try:
        result = PROVIDER.warm()
        return {
            "status": "warmed",
            "service": "eidon-orchestrator",
            "provider": result,
        }
    except ModelProviderError as exc:
        return {
            "status": "warm_failed",
            "service": "eidon-orchestrator",
            "provider": {
                "backend": PROVIDER.backend_name,
                "model": PROVIDER.model_name,
                "ready": False,
            },
            "provider_error_code": exc.error_code,
            "provider_error_message": exc.message,
        }


@app.get("/artifacts")
def list_artifacts(limit: int = 50) -> dict[str, object]:
    records = ARTIFACT_STORE.list_recent(limit=limit)
    return {
        "status": "found",
        "service": "eidon-orchestrator",
        "count": len(records),
        "artifacts": [record.model_dump() for record in records],
    }


@app.get("/artifacts/{artifact_id}")
def get_artifact_by_id(artifact_id: str) -> dict[str, object]:
    record = ARTIFACT_STORE.get(artifact_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Artifact not found: {artifact_id}")

    return {
        "status": "found",
        "service": "eidon-orchestrator",
        "artifact": record.model_dump(),
    }


@app.get("/lineage")
def list_lineage(limit: int = 50) -> dict[str, object]:
    records = LINEAGE_STORE.list_recent(limit=limit)
    return {
        "status": "found",
        "service": "eidon-orchestrator",
        "count": len(records),
        "lineage": [record.model_dump() for record in records],
    }


@app.get("/lineage/{artifact_id}")
def get_lineage(artifact_id: str) -> dict[str, object]:
    record = LINEAGE_STORE.get_by_artifact_id(artifact_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"Lineage not found for artifact: {artifact_id}")

    return {
        "status": "found",
        "service": "eidon-orchestrator",
        "lineage": record.model_dump(),
    }


@app.post("/orchestrate")
def orchestrate(payload: EidonOrchestrationInput) -> dict[str, object]:
    try:
        response_text = PROVIDER.generate_response(intent=payload.intent, content=payload.content)
        artifact = build_artifact(
            payload,
            storage_backend=ARTIFACT_STORE.backend_name,
            provider_backend=PROVIDER.backend_name,
            provider_model=PROVIDER.model_name,
            status="orchestrated",
            response_text=response_text,
            provider_status="succeeded",
        )
        saved_artifact = ARTIFACT_STORE.upsert(artifact)
        lineage = build_lineage_record(saved_artifact)
        saved_lineage = LINEAGE_STORE.upsert(lineage)

        return {
            "status": "orchestrated",
            "service": "eidon-orchestrator",
            "session_id": saved_artifact.session_id,
            "signal_id": saved_artifact.signal_id,
            "artifact_id": saved_artifact.artifact_id,
            "lineage_id": saved_lineage.lineage_id,
            "storage_backend": saved_artifact.storage_backend,
            "provider_backend": saved_artifact.provider_backend,
            "provider_model": saved_artifact.provider_model,
            "provider_status": saved_artifact.provider_status,
            "message": "Eidon scaffold orchestrated the request through a warmed provider adapter and persisted artifact and lineage records.",
        }
    except ModelProviderError as exc:
        failure_text = f"Provider failure recorded: {exc.error_code}"
        artifact = build_artifact(
            payload,
            storage_backend=ARTIFACT_STORE.backend_name,
            provider_backend=PROVIDER.backend_name,
            provider_model=PROVIDER.model_name,
            status="provider_failed",
            response_text=failure_text,
            provider_status="failed",
            provider_error_code=exc.error_code,
            provider_error_message=exc.message,
        )
        saved_artifact = ARTIFACT_STORE.upsert(artifact)
        lineage = build_lineage_record(saved_artifact)
        saved_lineage = LINEAGE_STORE.upsert(lineage)

        return {
            "status": "provider_failed",
            "service": "eidon-orchestrator",
            "session_id": saved_artifact.session_id,
            "signal_id": saved_artifact.signal_id,
            "artifact_id": saved_artifact.artifact_id,
            "lineage_id": saved_lineage.lineage_id,
            "storage_backend": saved_artifact.storage_backend,
            "provider_backend": saved_artifact.provider_backend,
            "provider_model": saved_artifact.provider_model,
            "provider_status": saved_artifact.provider_status,
            "provider_error_code": saved_artifact.provider_error_code,
            "provider_error_message": saved_artifact.provider_error_message,
            "message": "Eidon scaffold recorded a provider failure and persisted artifact and lineage failure provenance.",
        }
