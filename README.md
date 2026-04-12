# Eidonic Core

Implementation repository for the Eidonic Core.

This repo contains the executable runtime, services, shared schemas, scripts, tests, and docs for the current living core scaffold.

## Current phase
Phase 2 scaffold with chained services, PostgreSQL-backed state spine, real local provider integration, integrated proof coverage, and local measurement surfaces.

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
- startup-enforced provider warmup
- startup-enforced runtime preflight

## Current model policy
- primary local model family: `Gemma`
- current default live model: `gemma3n:e4b`
- Gemma-family variants are the normal future candidates
- non-Gemma models are tooling probes unless explicitly elevated by evidence

## Current measurement surface
- local provider eval surface
- pinned local provider eval baseline
- isolated candidate comparison workflow
- written model-family policy

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
- provider warmup failure surface

## Current local measurement workflow
Run the local provider eval surface from repo root:

`powershell -ExecutionPolicy Bypass -File .\scripts\run_local_provider_eval.ps1`

Compare the current eval output to the pinned baseline:

`powershell -ExecutionPolicy Bypass -File .\scripts\compare_local_provider_eval_to_baseline.ps1`

Run an isolated alternate-model comparison without changing the live default:

`powershell -ExecutionPolicy Bypass -File .\scripts\run_local_provider_candidate_eval.ps1 -CandidateModel "<installed-model-name>"`

## Working rules
- terminal-first local workflow
- one narrow branch at a time
- after every merge, update local first
- prove changes from `main` after merge
- no live hosted model in runtime
- persistence, provenance, failure semantics, readiness, preflight, startup discipline, and measurement before model complexity

## Local workflow
Optional standalone preflight from repo root:

`powershell -ExecutionPolicy Bypass -File .\scripts\check_phase_2_runtime_prereqs.ps1`

Standard stack startup from repo root:

`powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1`

The standard startup sequence now does this automatically:
1. runtime preflight
2. service boot
3. health wait
4. provider warmup

Run happy-path integration proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_full_chain.ps1`

Run focused provider-failure proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_provider_failure_surface.ps1`

Run focused provider-warmup proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_provider_warmup_surface.ps1`

Run focused provider-warmup failure proof from repo root:

`powershell -ExecutionPolicy Bypass -File .\tests\integration\test_provider_warmup_failure_surface.ps1`

## Notes
PostgreSQL now backs the current proven Phase 2 state spine.

Local JSON adapters remain in the repo as fallback implementations, not as the current proven primary backend.

Preflight exists to catch missing local prerequisites before startup.

The stack launcher now enforces that preflight before boot instead of relying on memory or ritual.

Gemma is the current primary local model family, and `gemma3n:e4b` remains the proven default live model until evidence justifies a future pilot.
