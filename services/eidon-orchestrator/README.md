# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- record provider provenance alongside orchestration output
- return artifact and lineage identifiers
- expose list and retrieval surfaces for persisted orchestrator records
- route response generation through a provider adapter surface

## Current phase
Phase 2 PostgreSQL-backed orchestration service with persisted provider provenance

## Current endpoints
- `GET /health`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Store contract surface
`eidon-orchestrator` expects its storage backends to support:
- artifact store: `backend_name`, `upsert(record)`, `get(artifact_id)`, `list_recent(limit)`, `ping()`
- lineage store: `backend_name`, `upsert(record)`, `get_by_artifact_id(artifact_id)`, `list_recent(limit)`, `ping()`

## Provider contract surface
`eidon-orchestrator` expects its response provider to support:
- `backend_name`
- `model_name`
- `generate_response(intent, content)`
- `ping()`

## Current persisted provenance
Artifact records now persist:
- `storage_backend`
- `provider_backend`
- `provider_model`

Lineage records now persist:
- `artifact_storage_backend`
- `artifact_provider_backend`
- `artifact_provider_model`

## Notes
This branch hardens traceability. It does not add routing or training.
