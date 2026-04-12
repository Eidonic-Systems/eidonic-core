import json
import os
from typing import Any, Protocol

import httpx


class ModelProviderError(Exception):
    def __init__(self, error_code: str, message: str):
        super().__init__(message)
        self.error_code = error_code
        self.message = message


class ProviderUnavailableError(ModelProviderError):
    def __init__(self, message: str = "Provider is unavailable."):
        super().__init__("provider_unavailable", message)


class ProviderTimeoutError(ModelProviderError):
    def __init__(self, message: str = "Provider request timed out."):
        super().__init__("provider_timeout", message)


class ProviderModelMissingError(ModelProviderError):
    def __init__(self, model_name: str):
        super().__init__("provider_model_missing", f"Provider model is not available locally: {model_name}")


class ProviderEmptyResponseError(ModelProviderError):
    def __init__(self):
        super().__init__("provider_empty_response", "Provider returned an empty response.")


class ProviderHttpError(ModelProviderError):
    def __init__(self, message: str):
        super().__init__("provider_http_error", message)


class ModelProvider(Protocol):
    @property
    def backend_name(self) -> str: ...

    @property
    def model_name(self) -> str: ...

    def generate_response(self, *, intent: str, content: dict[str, Any]) -> str: ...

    def ping(self) -> dict[str, object]: ...

    def warm(self) -> dict[str, object]: ...


class StubModelProvider:
    def __init__(self, model_name: str = "stub-eidon-v1"):
        self._model_name = model_name
        self._ready = True

    @property
    def backend_name(self) -> str:
        return "stub"

    @property
    def model_name(self) -> str:
        return self._model_name

    def generate_response(self, *, intent: str, content: dict[str, Any]) -> str:
        self._ready = True
        user_text = content.get("text")
        if isinstance(user_text, str) and user_text.strip():
            return f"Eidon received the intent: {intent}"
        return f"Eidon is prepared to act on the intent: {intent}"

    def ping(self) -> dict[str, object]:
        return {
            "status": "ok",
            "backend": self.backend_name,
            "model": self.model_name,
            "ready": self._ready,
        }

    def warm(self) -> dict[str, object]:
        self._ready = True
        return {
            "status": "ok",
            "backend": self.backend_name,
            "model": self.model_name,
            "ready": self._ready,
        }


class OllamaModelProvider:
    def __init__(self, base_url: str, model_name: str, timeout_seconds: float = 30.0, warm_keepalive: str = "15m"):
        self.base_url = base_url.rstrip("/")
        self._model_name = model_name
        self.timeout_seconds = timeout_seconds
        self.warm_keepalive = warm_keepalive
        self.timeout = httpx.Timeout(timeout_seconds, connect=min(timeout_seconds, 10.0))
        self._ready = False

    @property
    def backend_name(self) -> str:
        return "ollama"

    @property
    def model_name(self) -> str:
        return self._model_name

    def _request(self, method: str, path: str, *, json_body: dict[str, Any] | None = None) -> dict[str, Any]:
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.request(method, f"{self.base_url}{path}", json=json_body)
                response.raise_for_status()
                return response.json()
        except httpx.ConnectTimeout as exc:
            raise ProviderTimeoutError("Provider connection timed out.") from exc
        except httpx.ReadTimeout as exc:
            raise ProviderTimeoutError("Provider response timed out.") from exc
        except httpx.TimeoutException as exc:
            raise ProviderTimeoutError() from exc
        except httpx.ConnectError as exc:
            raise ProviderUnavailableError("Could not connect to the provider.") from exc
        except httpx.HTTPStatusError as exc:
            raise ProviderHttpError(f"Provider returned HTTP {exc.response.status_code}.") from exc
        except httpx.HTTPError as exc:
            raise ProviderUnavailableError(str(exc)) from exc

    def _list_models(self) -> list[dict[str, Any]]:
        payload = self._request("GET", "/tags")
        models = payload.get("models")
        if not isinstance(models, list):
            raise ProviderHttpError("Provider tags response did not include a models list.")
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
            raise ProviderModelMissingError(self.model_name)

    def _strip_code_fence(self, text: str) -> str:
        trimmed = text.strip()
        if not trimmed.startswith("```"):
            return trimmed

        lines = trimmed.splitlines()
        if len(lines) < 3:
            return trimmed

        if not lines[-1].strip().startswith("```"):
            return trimmed

        body_lines = lines[1:-1]
        return "\n".join(body_lines).strip()

    def _unwrap_json_response(self, text: str) -> str:
        trimmed = text.strip()
        if not (trimmed.startswith("{") and trimmed.endswith("}")):
            return trimmed

        try:
            payload = json.loads(trimmed)
        except json.JSONDecodeError:
            return trimmed

        if isinstance(payload, dict):
            for key in ("response", "text", "message"):
                value = payload.get(key)
                if isinstance(value, str) and value.strip():
                    return value.strip()

        return trimmed

    def _normalize_plain_text(self, text: str) -> str:
        normalized = text.strip()
        normalized = self._strip_code_fence(normalized)
        normalized = self._unwrap_json_response(normalized)
        normalized = normalized.strip()
        return normalized

    def generate_response(self, *, intent: str, content: dict[str, Any]) -> str:
        self._ensure_model_available()

        prompt = "\n".join([
            "You are Eidon, a disciplined orchestration model inside Eidonic Core.",
            "Respond plainly and usefully in 1 to 3 sentences.",
            "Return plain text only.",
            "Do not use JSON.",
            "Do not use Markdown code fences.",
            "Do not wrap the answer in keys like response, text, or message.",
            f"Intent: {intent}",
            f"Content: {json.dumps(content, ensure_ascii=False, sort_keys=True)}",
        ])

        payload = self._request("POST", "/generate", json_body={
            "model": self.model_name,
            "prompt": prompt,
            "stream": False,
            "keep_alive": self.warm_keepalive,
        })

        generated = payload.get("response")
        if not isinstance(generated, str) or not generated.strip():
            raise ProviderEmptyResponseError()

        normalized = self._normalize_plain_text(generated)
        if not normalized:
            raise ProviderEmptyResponseError()

        self._ready = True
        return normalized

    def ping(self) -> dict[str, object]:
        self._ensure_model_available()
        return {
            "status": "ok",
            "backend": self.backend_name,
            "model": self.model_name,
            "base_url": self.base_url,
            "ready": self._ready,
        }

    def warm(self) -> dict[str, object]:
        self._ensure_model_available()
        self._request("POST", "/generate", json_body={
            "model": self.model_name,
            "prompt": "Warm the model and reply with ok.",
            "stream": False,
            "keep_alive": self.warm_keepalive,
        })
        self._ready = True
        return {
            "status": "ok",
            "backend": self.backend_name,
            "model": self.model_name,
            "base_url": self.base_url,
            "ready": self._ready,
        }


def build_model_provider() -> ModelProvider:
    backend = os.getenv("EIDON_PROVIDER_BACKEND", "stub").strip().lower()
    model_name = os.getenv("EIDON_PROVIDER_MODEL", "stub-eidon-v1").strip() or "stub-eidon-v1"

    if backend == "stub":
        return StubModelProvider(model_name=model_name)

    if backend == "ollama":
        base_url = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434/api").strip() or "http://127.0.0.1:11434/api"
        timeout_raw = os.getenv("EIDON_PROVIDER_TIMEOUT_SECONDS", "30").strip() or "30"
        warm_keepalive = os.getenv("EIDON_PROVIDER_WARM_KEEPALIVE", "15m").strip() or "15m"
        timeout_seconds = float(timeout_raw)
        return OllamaModelProvider(
            base_url=base_url,
            model_name=model_name,
            timeout_seconds=timeout_seconds,
            warm_keepalive=warm_keepalive,
        )

    raise RuntimeError(f"Unsupported EIDON_PROVIDER_BACKEND: {backend}")
