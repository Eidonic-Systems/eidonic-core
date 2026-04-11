import os
from typing import Any, Protocol


class ModelProvider(Protocol):
    @property
    def backend_name(self) -> str: ...

    @property
    def model_name(self) -> str: ...

    def generate_response(self, *, intent: str, content: dict[str, Any]) -> str: ...

    def ping(self) -> dict[str, str]: ...


class StubModelProvider:
    def __init__(self, model_name: str = "stub-eidon-v1"):
        self._model_name = model_name

    @property
    def backend_name(self) -> str:
        return "stub"

    @property
    def model_name(self) -> str:
        return self._model_name

    def generate_response(self, *, intent: str, content: dict[str, Any]) -> str:
        user_text = content.get("text")
        if isinstance(user_text, str) and user_text.strip():
            return f"Eidon received the intent: {intent}"
        return f"Eidon is prepared to act on the intent: {intent}"

    def ping(self) -> dict[str, str]:
        return {
            "status": "ok",
            "backend": self.backend_name,
            "model": self.model_name,
        }


def build_model_provider() -> ModelProvider:
    backend = os.getenv("EIDON_PROVIDER_BACKEND", "stub").strip().lower()
    model_name = os.getenv("EIDON_PROVIDER_MODEL", "stub-eidon-v1").strip() or "stub-eidon-v1"

    if backend == "stub":
        return StubModelProvider(model_name=model_name)

    raise RuntimeError(f"Unsupported EIDON_PROVIDER_BACKEND: {backend}")
