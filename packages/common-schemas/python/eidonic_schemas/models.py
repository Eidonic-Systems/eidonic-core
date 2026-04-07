from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field

SignalType = Literal["user_message", "file_upload", "system_event", "command"]
SignalSource = Literal["chat", "upload", "internal", "api"]
SensitivityHint = Literal["low", "moderate", "high", "unknown"]
ThresholdResult = Literal["pass", "hold", "escalate"]


class SignalEventInput(BaseModel):
    schema_version: Literal["1.0.0"]
    signal_id: str
    signal_type: SignalType
    source: SignalSource
    content: dict[str, Any]
    created_at: datetime
    session_hint: str | None = None
    sensitivity_hint: SensitivityHint | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class HeraldCheckInput(BaseModel):
    signal_id: str
    signal_type: SignalType
    source: SignalSource
    sensitivity_hint: SensitivityHint | None = None
    content: dict[str, Any]


class SessionStartInput(BaseModel):
    signal_id: str
    signal_type: SignalType
    source: SignalSource
    threshold_result: ThresholdResult
    content: dict[str, Any]


class EidonOrchestrationInput(BaseModel):
    session_id: str
    signal_id: str
    signal_type: SignalType
    source: SignalSource
    threshold_result: ThresholdResult
    intent: str
    content: dict[str, Any]
