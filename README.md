# Eidonic Core

Implementation repository for the Eidonic Core.

This repo contains the executable runtime, services, shared schemas, scripts, tests, and docs for the current living core scaffold.

## Current phase
Phase 2 scaffold with chained services, PostgreSQL-backed state spine, real local provider integration, and integrated proof coverage.

## Current live chain
`signal-gateway` -> `herald-service` -> `session-engine` -> `eidon-orchestrator`

## Current verified persistence
- `SignalRecord` via PostgreSQL
- `ThresholdRecord` via PostgreSQL
- `SessionRecord` via PostgreSQL
- `EidonArtifactRecord` via PostgreSQL
- `ArtifactLineageRecord` via PostgreSQL

## Current verified provider surface
- provider contract in Orchestrator
- local Ollama-backed provider adapter
- persisted provider provenance
- persisted provider failure semantics
- explicit provider warmup and readiness surface

## Fallback persistence still available
- local JSON store adapters remain available as fallback
- the current proven local stack uses PostgreSQL-backed services

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
  - `POST /provider/warm`
  - `POST /orchestrate`
  - `GET /artifacts`
  - `GET /artifacts/{artifact_id}`
  - `GET /lineage`
  - `GET /lineage/{artifact_id}`

## Current integration proof
The standard integration coverage now verifies:
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
- service health on all four services
- list-limit behavior across current list surfaces
- provider surface health
- provider provenance retrieval
- provider failure surface
- provider warmup surface

## Working rules
- terminal-first local workflow
- one narrow branch at a time
- after every merge, update local first
- prove changes from `main` after merge
- no live hosted model in runtime
- persistence, provenance, failure semantics, and readiness before model complexity

## Local workflow
Start stack from repo root:

`powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1`

This now starts the four service windows, waits for health, and warms the Eidon provider before handing control back.

Run happy-path integration proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_full_chain.ps1`

Run focused provider-failure proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_provider_failure_surface.ps1`

Run focused provider-warmup proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_provider_warmup_surface.ps1`

## Notes
PostgreSQL now backs the current proven Phase 2 state spine.

Local JSON adapters remain in the repo as fallback implementations, not as the current proven primary backend.

The stack startup sequence now includes provider warmup so the local system enters a ready state instead of relying on a manual warmup ritual.
