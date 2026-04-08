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


class HeraldCheckInput(BaseModel):
    signal_id: str
    signal_type: Literal["user_message", "file_upload", "system_event", "command"]
    source: Literal["chat", "upload", "internal", "api"]
    sensitivity_hint: Literal["low", "moderate", "high", "unknown"] | None = None
    content: dict[str, Any]


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
    status: Literal["orchestrated"]
    response_text: str
    created_at: str
    storage_backend: Literal["local_json", "postgres"]
