# AGENTS.md

This repository is built in narrow, proven phases.

## Rules
- Do not invent architecture beyond the current proven phase.
- Prefer small pull requests.
- Do not add dependencies casually.
- Preserve typed schemas and version fields.
- Keep persistence, provenance, readiness, failure surfaces, and eval surfaces explicit.
- Add tests for behavior changes and new retrieval surfaces.
- After every merge, update local first.
- Prove changes from `main`, not only from the feature branch.
- Keep implementation grounded in current repo documents and current passing behavior.

## Current build truth
Phase 2 scaffold is live and proven.

Current live chain:
- `signal-gateway`
- `herald-service`
- `session-engine`
- `eidon-orchestrator`

Current verified persistence:
- `SignalRecord` via PostgreSQL
- `ThresholdRecord` via PostgreSQL
- `SessionRecord` via PostgreSQL
- `EidonArtifactRecord` via PostgreSQL
- `ArtifactLineageRecord` via PostgreSQL

Current verified provider/runtime surface:
- local Ollama-backed provider adapter
- persisted provider provenance
- persisted provider failure semantics
- explicit provider warmup and readiness
- startup-enforced provider warmup
- startup-enforced runtime preflight
- local provider eval surface
- pinned local provider eval baseline
- isolated candidate comparison workflow

## Model-family policy
Primary local model family:
- `Gemma`

Current default live model:
- `gemma3n:e4b`

Model classes:
- default live model
- Gemma-family candidates
- non-Gemma tooling probes

Policy:
- the system is Gemma-family-centered unless evidence forces a change
- Gemma-family variants are the normal candidates for future comparison
- non-Gemma models may be used to validate eval or comparison tooling, but they are not the default architectural direction
- no default-model change happens without a written decision and evidence from the eval and comparison surfaces

Fallback persistence still available:
- `LocalJsonSignalStore`
- `LocalJsonThresholdStore`
- `LocalJsonSessionStore`
- `LocalJsonArtifactStore`
- `LocalJsonArtifactLineageStore`

Current discipline:
- terminal-only for local build and test steps
- GitHub web UI for PR creation and merge
- one real change per branch
- update local after every merge
- local model in runtime is allowed and now proven
- routing, second-model support, and training come after reliability and measurement surfaces are hardened

## Current working sequence
1. contract surface
2. persistence surface
3. retrieval surface
4. integration proof
5. provider boundary
6. provider provenance
7. provider failure semantics
8. provider warmup and readiness
9. startup and preflight discipline
10. eval surface
11. eval baseline
12. candidate comparison
13. written decision
14. truth sync

Do not skip ahead to fake future systems.
