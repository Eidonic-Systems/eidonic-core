import json
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
    provider_route_mode: str | None = None,
    provider_route_reason: str | None = None,
    governance_outcome: str | None = None,
    governance_reason: str | None = None,
    governance_rule_id: str | None = None,
    governance_manifest_version: str | None = None,
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
        provider_route_mode=provider_route_mode,
        provider_route_reason=provider_route_reason,
        governance_outcome=governance_outcome or "",
        governance_reason=governance_reason or "",
        governance_rule_id=governance_rule_id or "",
        governance_manifest_version=governance_manifest_version or "",
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
        artifact_provider_route_mode=artifact.provider_route_mode,
        artifact_provider_route_reason=artifact.provider_route_reason,
        artifact_governance_outcome=artifact.governance_outcome,
        artifact_governance_reason=artifact.governance_reason,
        artifact_governance_rule_id=artifact.governance_rule_id,
        artifact_governance_manifest_version=artifact.governance_manifest_version,
        artifact_provider_error_code=artifact.provider_error_code,
        artifact_provider_error_message=artifact.provider_error_message,
        artifact_kind="eidon_orchestration",
        created_at=datetime.now(timezone.utc).isoformat(),
    )


REPO_ROOT = Path(__file__).resolve().parents[3]
GOVERNANCE_RULES_MANIFEST_PATH = REPO_ROOT / "config" / "governance_rules_manifest.json"


def load_governance_rules_manifest():
    with GOVERNANCE_RULES_MANIFEST_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def get_governance_manifest_metadata(governance_outcome, governance_reason):
    manifest = load_governance_rules_manifest()
    manifest_version = str(manifest.get("manifest_version", "")).strip()

    default_success = manifest.get("default_success", {})
    if (
        governance_outcome == str(default_success.get("governance_outcome", "")).strip()
        and governance_reason == str(default_success.get("governance_reason", "")).strip()
    ):
        return (
            str(default_success.get("rule_id", "")).strip(),
            manifest_version,
        )

    rules = manifest.get("rules", [])
    for rule in rules:
        if not isinstance(rule, dict):
            continue

        if (
            governance_outcome == str(rule.get("governance_outcome", "")).strip()
            and governance_reason == str(rule.get("governance_reason", "")).strip()
        ):
            return (
                str(rule.get("rule_id", "")).strip(),
                manifest_version,
            )

    return ("", "")


def evaluate_governance_pilot(payload):
    manifest = load_governance_rules_manifest()
    content = payload.content if isinstance(payload.content, dict) else {}
    raw_text = content.get("text")
    text_value = raw_text.strip().lower() if isinstance(raw_text, str) else ""
    serialized_content = json.dumps(content, ensure_ascii=False, sort_keys=True).lower()
    intent_value = payload.intent.strip().lower() if isinstance(payload.intent, str) else ""
    combined = f"{intent_value} {text_value} {serialized_content}".strip()

    rules = manifest.get("rules", [])
    for rule in rules:
        if not isinstance(rule, dict):
            continue

        if not rule.get("enabled", False):
            continue

        signal_types = rule.get("signal_types", [])
        if isinstance(signal_types, list) and signal_types and payload.signal_type not in signal_types:
            continue

        patterns = rule.get("patterns", [])
        if not isinstance(patterns, list) or not patterns:
            continue

        match_mode = str(rule.get("match_mode", "contains_any")).strip().lower()
        normalized_patterns = [str(p).strip().lower() for p in patterns if str(p).strip()]

        matched = False
        if match_mode == "contains_any":
            matched = any(pattern in combined for pattern in normalized_patterns)
        elif match_mode == "contains_all":
            matched = all(pattern in combined for pattern in normalized_patterns)

        if not matched:
            continue

        return (
            str(rule.get("governance_outcome", "")).strip(),
            str(rule.get("governance_reason", "")).strip(),
            str(rule.get("response_text", "")).strip(),
        )

    return None


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
    governance_pilot = evaluate_governance_pilot(payload)
    if governance_pilot is not None:
        governance_outcome, governance_reason, response_text = governance_pilot
        artifact = build_artifact(
            payload,
            storage_backend=ARTIFACT_STORE.backend_name,
            provider_backend=PROVIDER.backend_name,
            provider_model=PROVIDER.model_name,
            status="orchestrated",
            response_text=response_text,
            provider_status="not_invoked",
            provider_route_mode="control",
            provider_route_reason="control_default_no_routing",
            provider_error_code=None,
            provider_error_message=None,
            governance_outcome=governance_outcome,
            governance_reason=governance_reason,
            governance_rule_id=get_governance_manifest_metadata(governance_outcome, governance_reason)[0],
            governance_manifest_version=get_governance_manifest_metadata(governance_outcome, governance_reason)[1],
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
            "provider_route_mode": saved_artifact.provider_route_mode,
            "provider_route_reason": saved_artifact.provider_route_reason,
            "governance_outcome": saved_artifact.governance_outcome,
            "governance_reason": saved_artifact.governance_reason,
            "governance_rule_id": saved_artifact.governance_rule_id,
            "governance_manifest_version": saved_artifact.governance_manifest_version,
            "message": "Eidon scaffold applied a narrow governance enforcement pilot and persisted artifact and lineage records.",
        }

    try:
        response_text = PROVIDER.generate_response(intent=payload.intent, content=payload.content)
        artifact = build_artifact(
            payload,
            storage_backend=ARTIFACT_STORE.backend_name,
            provider_backend=PROVIDER.backend_name,
            provider_model=getattr(PROVIDER, "_last_selected_model", PROVIDER.model_name),
            status="orchestrated",
            response_text=response_text,
            provider_status="succeeded",
            governance_outcome="allow",
            governance_reason="normal_orchestration_path",
            governance_rule_id=get_governance_manifest_metadata("allow", "normal_orchestration_path")[0],
            governance_manifest_version=get_governance_manifest_metadata("allow", "normal_orchestration_path")[1],
            provider_route_mode=(
                "candidate"
                if getattr(PROVIDER, "_last_route_reason", "") == "candidate_domain_route"
                else "fallback"
                if getattr(PROVIDER, "_last_route_reason", "") == "control_fallback_after_candidate_failure"
                else getattr(PROVIDER, "_last_route_mode", "control")
            ),
            provider_route_reason=getattr(PROVIDER, "_last_route_reason", "control_default_no_routing"),
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
            "provider_route_mode": saved_artifact.provider_route_mode,
            "provider_route_reason": saved_artifact.provider_route_reason,
            "message": "Eidon scaffold orchestrated the request through a warmed provider adapter and persisted artifact and lineage records.",
        }
    except ModelProviderError as exc:
        failure_text = f"Provider failure recorded: {exc.error_code}"
        artifact = build_artifact(
            payload,
            storage_backend=ARTIFACT_STORE.backend_name,
            provider_backend=PROVIDER.backend_name,
            provider_model=getattr(PROVIDER, "_last_selected_model", PROVIDER.model_name),
            status="provider_failed",
            response_text=failure_text,
            provider_status="failed",
            provider_route_mode=(
                "candidate"
                if getattr(PROVIDER, "_last_route_reason", "") == "candidate_domain_route"
                else "fallback"
                if getattr(PROVIDER, "_last_route_reason", "") == "control_fallback_after_candidate_failure"
                else getattr(PROVIDER, "_last_route_mode", "control")
            ),
            provider_route_reason=getattr(PROVIDER, "_last_route_reason", "control_default_no_routing"),
            governance_outcome="fallback",
            governance_reason="provider_failure_recorded",
            governance_rule_id="",
            governance_manifest_version="",
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
            "provider_route_mode": saved_artifact.provider_route_mode,
            "provider_route_reason": saved_artifact.provider_route_reason,
            "provider_error_code": saved_artifact.provider_error_code,
            "provider_error_message": saved_artifact.provider_error_message,
            "governance_outcome": saved_artifact.governance_outcome,
            "governance_reason": saved_artifact.governance_reason,
            "governance_rule_id": saved_artifact.governance_rule_id,
            "governance_manifest_version": saved_artifact.governance_manifest_version,
            "message": "Eidon scaffold recorded a provider failure and persisted artifact and lineage failure provenance.",
        }
