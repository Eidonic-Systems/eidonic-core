import json
import os
from typing import Any, Protocol

import httpx
from fastapi import HTTPException


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


class OllamaModelProvider:
    def __init__(self, base_url: str, model_name: str):
        self.base_url = base_url.rstrip("/")
        self._model_name = model_name
        self.timeout = httpx.Timeout(120.0, connect=10.0)

    @property
    def backend_name(self) -> str:
        return "ollama"

    @property
    def model_name(self) -> str:
        return self._model_name

    def _list_models(self) -> list[dict[str, Any]]:
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.get(f"{self.base_url}/tags")
                response.raise_for_status()
                payload = response.json()
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=500, detail=f"Ollama provider health check failed: {exc}") from exc

        models = payload.get("models")
        if not isinstance(models, list):
            raise HTTPException(status_code=500, detail="Ollama tags response is missing a models list.")
        return models

    def _ensure_model_available(self) -> None:
        models = self._list_models()
        names = set()
        for item in models:
            if isinstance(item, dict):
                name = item.get("name") or item.get("model")
                if isinstance(name, str) and name.strip():
                    names.add(name.strip())

        if self.model_name not in names:
            raise HTTPException(status_code=500, detail=f"Ollama model is not available locally: {self.model_name}")

    def generate_response(self, *, intent: str, content: dict[str, Any]) -> str:
        self._ensure_model_available()

        prompt = "\n".join([
            "You are Eidon, a disciplined orchestration model inside Eidonic Core.",
            "Respond plainly and usefully in 1 to 3 sentences.",
            f"Intent: {intent}",
            f"Content: {json.dumps(content, ensure_ascii=False, sort_keys=True)}",
        ])

        body = {
            "model": self.model_name,
            "prompt": prompt,
            "stream": False,
        }

        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.post(f"{self.base_url}/generate", json=body)
                response.raise_for_status()
                payload = response.json()
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=500, detail=f"Ollama generation failed: {exc}") from exc

        generated = payload.get("response")
        if not isinstance(generated, str) or not generated.strip():
            raise HTTPException(status_code=500, detail="Ollama returned an empty response.")

        return generated.strip()

    def ping(self) -> dict[str, str]:
        self._ensure_model_available()
        return {
            "status": "ok",
            "backend": self.backend_name,
            "model": self.model_name,
            "base_url": self.base_url,
        }


def build_model_provider() -> ModelProvider:
    backend = os.getenv("EIDON_PROVIDER_BACKEND", "stub").strip().lower()
    model_name = os.getenv("EIDON_PROVIDER_MODEL", "stub-eidon-v1").strip() or "stub-eidon-v1"

    if backend == "stub":
        return StubModelProvider(model_name=model_name)

    if backend == "ollama":
        base_url = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434/api").strip() or "http://127.0.0.1:11434/api"
        return OllamaModelProvider(base_url=base_url, model_name=model_name)

    raise RuntimeError(f"Unsupported EIDON_PROVIDER_BACKEND: {backend}")
