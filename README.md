# Eidonic Core

Implementation repository for the Eidonic Core.

This repo contains the executable runtime, services, shared schemas, scripts, tests, and docs for the current living core scaffold.

## Current phase
Phase 2 scaffold with chained services, local persistence surfaces, and integrated proof coverage.

## Current live chain
`signal-gateway` -> `herald-service` -> `session-engine` -> `eidon-orchestrator`

## Current verified persistence
- `SignalRecord` via local JSON
- `ThresholdRecord` via local JSON
- `SessionRecord` via local JSON
- `EidonArtifactRecord` via local JSON
- `ArtifactLineageRecord` via local JSON

## Current verified retrieval surfaces
- Signal Gateway
  - `GET /health`
  - `POST /signals/ingest`
  - `GET /signals`
  - `GET /signals/{signal_id}`
- Herald Service
  - `GET /health`
  - `POST /threshold/check`
  - `GET /thresholds`
  - `GET /thresholds/{signal_id}`
- Session Engine
  - `GET /health`
  - `POST /sessions/start`
  - `GET /sessions`
  - `GET /sessions/{session_id}`
- Eidon Orchestrator
  - `GET /health`
  - `POST /orchestrate`
  - `GET /artifacts`
  - `GET /artifacts/{artifact_id}`
  - `GET /lineage`
  - `GET /lineage/{artifact_id}`

## Current integration proof
The standard integration test now verifies:
- full chained gateway response
- signal retrieval
- signal list retrieval
- threshold retrieval
- threshold list retrieval
- session retrieval
- session list retrieval
- artifact retrieval
- lineage retrieval
- artifact list retrieval
- lineage list retrieval
- service health on `signal-gateway`
- service health on `herald-service`
- service health on `session-engine`
- service health on `eidon-orchestrator`

## Working rules
- terminal-first local workflow
- one narrow branch at a time
- after every merge, update local first
- prove changes from `main` after merge
- no live model in runtime yet
- persistence and lineage architecture before model runtime expansion

## Local workflow
Start stack from repo root:
`powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1`

Run integration test from repo root:
`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_full_chain.ps1`

## Notes
The current JSON stores are temporary scaffolds, not final databases.

The next architectural steps should stay narrow and continue hardening durable surfaces, contracts, and truthful repo documentation before any larger runtime expansion.
