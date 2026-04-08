# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- return an artifact identifier

## Current phase
Phase 2 local artifact contract scaffold

## Current endpoints
- `GET /health`
- `POST /orchestrate`
- `GET /artifacts/{artifact_id}`

## Orchestration artifact contract
The current implementation builds and stores a shared `EidonArtifactRecord` contract before writing it to the local JSON store.

## Local persistence
The current scaffold writes artifact records to:
`services/eidon-orchestrator/data/artifacts.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real durable backend is introduced.

## Notes
This is a temporary local artifact persistence step, not the final witness or memory layer.
