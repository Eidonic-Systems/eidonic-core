# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- return artifact and lineage identifiers

## Current phase
Phase 2 artifact lineage surface scaffold

## Current endpoints
- `GET /health`
- `POST /orchestrate`
- `GET /artifacts/{artifact_id}`
- `GET /lineage/{artifact_id}`

## Orchestration artifact contract
The current implementation builds and stores a shared `EidonArtifactRecord` contract.

## Artifact lineage surface
The current implementation also builds and stores a shared `ArtifactLineageRecord` contract that links:
- session
- signal
- artifact
- storage backend

## Local persistence
The current scaffold writes records to:
- `services/eidon-orchestrator/data/artifacts.json`
- `services/eidon-orchestrator/data/lineage.json`

Both files are ignored by Git and act as temporary local persistence layers.

## Notes
This is still a temporary local lineage step, not a final witness or graph layer.
