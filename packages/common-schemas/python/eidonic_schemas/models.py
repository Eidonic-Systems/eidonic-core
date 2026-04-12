from typing import Any, Literal

from pydantic import BaseModel, Field


class SignalEventInput(BaseModel):
    schema_version: Literal["1.0.0"]
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    content: dict[str, Any]
    created_at: str
    session_hint: str | None = None
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class SignalRecord(BaseModel):
    schema_version: Literal["1.0.0"]
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    content: dict[str, Any]
    created_at: str
    session_hint: str | None = None
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    status: Literal["accepted"]
    storage_backend: Literal["local_json", "postgres"]


class HeraldCheckInput(BaseModel):
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    content: dict[str, Any]


class ThresholdRecord(BaseModel):
    threshold_id: str
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    content: dict[str, Any]
    threshold_result: Literal["pass", "hold", "escalate"]
    status: Literal["reviewed"]
    message: str
    created_at: str
    storage_backend: Literal["local_json", "postgres"]


class SessionStartInput(BaseModel):
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    content: dict[str, Any]


class EidonOrchestrationInput(BaseModel):
    session_id: str
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    intent: str
    content: dict[str, Any]


class SessionRecord(BaseModel):
    session_id: str
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    content: dict[str, Any]
    status: Literal["started"]
    created_at: str
    storage_backend: Literal["local_json", "postgres"]


class EidonArtifactRecord(BaseModel):
    artifact_id: str
    session_id: str
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    intent: str
    content: dict[str, Any]
    status: Literal["orchestrated", "provider_failed"]
    response_text: str
    created_at: str
    storage_backend: Literal["local_json", "postgres"]
    provider_backend: str
    provider_model: str
    provider_status: Literal["succeeded", "failed"]
    provider_route_mode: str = ""
    provider_route_reason: str = ""
    provider_error_code: str | None = None
    provider_error_message: str | None = None


class ArtifactLineageRecord(BaseModel):
    lineage_id: str
    artifact_id: str
    session_id: str
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    threshold_result: Literal["pass", "hold", "escalate"]
    artifact_status: Literal["orchestrated", "provider_failed"]
    artifact_storage_backend: Literal["local_json", "postgres"]
    artifact_provider_backend: str
    artifact_provider_model: str
    artifact_provider_status: Literal["succeeded", "failed"]
    artifact_provider_route_mode: str = ""
    artifact_provider_route_reason: str = ""
    artifact_provider_error_code: str | None = None
    artifact_provider_error_message: str | None = None
    artifact_kind: Literal["eidon_orchestration"]
    created_at: str

