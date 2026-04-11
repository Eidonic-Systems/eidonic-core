# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- record provider provenance and provider failure truth alongside orchestration output
- return artifact and lineage identifiers
- expose list and retrieval surfaces for persisted orchestrator records
- route response generation through a provider adapter surface

## Current phase
Phase 2 PostgreSQL-backed orchestration service with explicit provider failure semantics

## Current endpoints
- `GET /health`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Provider failure semantics
The current provider layer distinguishes these failure classes:
- `provider_unavailable`
- `provider_timeout`
- `provider_model_missing`
- `provider_empty_response`
- `provider_http_error`

When provider generation fails, Orchestrator persists a `provider_failed` artifact and matching lineage record instead of collapsing the event into a vague server error.

## Persisted provider failure truth
Artifact records now persist:
- `provider_backend`
- `provider_model`
- `provider_status`
- `provider_error_code`
- `provider_error_message`

Lineage records now persist:
- `artifact_provider_backend`
- `artifact_provider_model`
- `artifact_provider_status`
- `artifact_provider_error_code`
- `artifact_provider_error_message`

## Notes
This branch hardens failure behavior and traceability. It does not add routing or training.
