# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- return artifact and lineage identifiers

## Current phase
Phase 2 store contract surface scaffold

## Current endpoints
- `GET /health`
- `POST /orchestrate`
- `GET /artifacts/{artifact_id}`
- `GET /lineage/{artifact_id}`

## Store contract surface
The current implementation now uses explicit local store adapters for both artifact and lineage persistence instead of keeping JSON persistence inline in the main service file.

## Local persistence
The current scaffold writes records to:
- `services/eidon-orchestrator/data/artifacts.json`
- `services/eidon-orchestrator/data/lineage.json`

Both files are ignored by Git and act as temporary local persistence layers.

## Notes
This is still a temporary local persistence layer, not a final witness, review, or database-backed system.
