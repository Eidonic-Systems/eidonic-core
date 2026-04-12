# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- record provider provenance and provider failure truth alongside orchestration output
- expose provider warmup and readiness surfaces
- return artifact and lineage identifiers
- expose list and retrieval surfaces for persisted orchestrator records
- route response generation through a provider adapter surface

## Current phase
Phase 2 PostgreSQL-backed orchestration service with local provider runtime hardening

## Current endpoints
- `GET /health`
- `POST /provider/warm`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Current persistence
- artifact records persisted in PostgreSQL
- lineage records persisted in PostgreSQL
- local JSON stores remain available as fallback only

## Current provider/runtime surface
- provider adapter contract
- local Ollama-backed provider
- persisted provider provenance
- persisted provider failure semantics
- explicit warmup surface
- explicit readiness truth
- plain-text response guard in the Ollama provider path
- narrow domain-task routing pilot surface with control fallback

## Persisted provider provenance
Artifact records persist:
- `provider_backend`
- `provider_model`
- `provider_status`
- `provider_error_code`
- `provider_error_message`

Lineage records persist:
- `artifact_provider_backend`
- `artifact_provider_model`
- `artifact_provider_status`
- `artifact_provider_error_code`
- `artifact_provider_error_message`

## Warmup and readiness
- `POST /provider/warm` warms the selected provider
- `GET /health` exposes `provider.ready`
- `scripts/warm_eidon_provider.ps1` provides a direct warmup entry point
- `scripts/start_phase_2_stack.ps1` now runs warmup automatically after service health passes

## Failure semantics
The current provider layer distinguishes:
- `provider_unavailable`
- `provider_timeout`
- `provider_model_missing`
- `provider_empty_response`
- `provider_http_error`

When provider generation fails, Orchestrator persists a `provider_failed` artifact and matching lineage record instead of collapsing the event into a vague server error.

## Plain-text response guard
The Ollama provider path now:
- explicitly instructs the model to return plain text only
- rejects wrapper-style JSON behavior by normalizing common response wrappers
- strips fenced Markdown code blocks when the model leaks wrapper formatting

## Domain-task routing pilot
The current pilot is narrow and optional.

Environment flags:
- `EIDON_DOMAIN_ROUTING_ENABLED`
- `EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL`

Pilot rules:
- control model remains `EIDON_PROVIDER_MODEL`
- only a small allowlist of domain-task patterns is route-eligible
- candidate failure falls back to the control model
- the chosen model is reflected in persisted provenance
- runtime routing beyond this pilot is not yet live

## Current proven local provider
- backend: `ollama`
- control model: `gemma3n:e4b`

## Notes
This service is now beyond simple persistence scaffolding. The next layers should stay focused on reliability, operational discipline, and measured runtime evolution rather than premature model complexity.
