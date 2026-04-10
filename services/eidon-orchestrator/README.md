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
Phase 2 Postgres-ready orchestrator store contract scaffold

## Current endpoints
- `GET /health`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Store contract surface
The current implementation uses explicit artifact and lineage store contracts with `upsert`, retrieval, `list_recent(limit)`, and `ping()` semantics.

The active implementations are still local JSON stores, but the contract surface is now shaped for a future durable backend without changing current runtime behavior.

## Local persistence
The current scaffold writes records to:
- `services/eidon-orchestrator/data/artifacts.json`
- `services/eidon-orchestrator/data/lineage.json`

Both files are ignored by Git and act as temporary local persistence layers.

## Notes
This is still not a final witness, review, or database-backed system.
