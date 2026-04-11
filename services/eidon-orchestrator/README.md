# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a simple artifact lineage record
- record provider provenance and provider failure truth alongside orchestration output
- expose provider warmup and readiness surfaces
- return artifact and lineage identifiers
- expose list and retrieval surfaces for persisted orchestrator records
- route response generation through a provider adapter surface

## Current phase
Phase 2 PostgreSQL-backed orchestration service with provider warmup and readiness surfaces

## Current endpoints
- `GET /health`
- `POST /provider/warm`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Provider warmup surface
- `POST /provider/warm` warms the currently selected provider
- `GET /health` exposes provider readiness through `provider.ready`
- `scripts/warm_eidon_provider.ps1` gives the repo a simple deterministic warmup entry point

## Current provider readiness truth
- before warmup, Ollama may be available but not yet ready in-process
- after warmup, `provider.ready` should report `true`
- successful orchestration also marks the provider as ready

## Warmup configuration
- `EIDON_PROVIDER_WARM_KEEPALIVE=15m`

## Notes
This branch makes cold-start state visible and controllable. It does not add routing, training, or a second model.
