# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- return artifact and lineage identifiers
- expose list and retrieval surfaces for persisted orchestrator records
- route response generation through a provider adapter surface

## Current phase
Phase 2 PostgreSQL-backed orchestration service with an Ollama provider adapter pilot

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

## Current adapter implementations
- `OllamaModelProvider`
- `StubModelProvider`
- `PostgresArtifactStore`
- `PostgresArtifactLineageStore`
- `LocalJsonArtifactStore`
- `LocalJsonArtifactLineageStore`

## Current proven backends
- persistence: PostgreSQL
- provider: Ollama
- model: `gemma3n:e4b`

## Backend selection
Choose the active backends through environment variables:
- `ORCHESTRATOR_STORE_BACKEND=postgres` or `local_json`
- `ORCHESTRATOR_POSTGRES_DSN=postgresql://...`
- `EIDON_PROVIDER_BACKEND=ollama` or `stub`
- `EIDON_PROVIDER_MODEL=gemma3n:e4b`
- `OLLAMA_BASE_URL=http://127.0.0.1:11434/api`

## Notes
The Ollama adapter is the first real local model runtime path. Training and routing are not part of this branch.
