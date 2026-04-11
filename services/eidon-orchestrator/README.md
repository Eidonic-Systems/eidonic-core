# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- return artifact and lineage identifiers
- expose list and retrieval surfaces for persisted orchestrator records

## Current phase
Phase 2 Postgres backend pilot

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

## Current adapter implementations
- `LocalJsonArtifactStore`
- `LocalJsonArtifactLineageStore`
- `PostgresArtifactStore`
- `PostgresArtifactLineageStore`

## Backend selection
Choose the active backend through environment variables:
- `ORCHESTRATOR_STORE_BACKEND=local_json` or `postgres`
- `ORCHESTRATOR_POSTGRES_DSN=postgresql://...`

## Why this matters
This is the fourth real durable-backend pilot for the Phase 2 scaffold. The goal is to prove database-backed artifact and lineage stores without changing HTTP behavior.

## Notes
Local JSON remains available as fallback during the pilot.
