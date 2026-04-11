# AGENTS.md

This repository is built in narrow, proven phases.

## Rules
- Do not invent architecture beyond the current proven phase.
- Prefer small pull requests.
- Do not add dependencies casually.
- Preserve typed schemas and version fields.
- Keep persistence and retrieval surfaces explicit.
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
- no live model in runtime yet
- persistence and lineage architecture before model runtime integration

## Current working sequence
1. contract surface
2. local persistence surface
3. retrieval surface
4. integration proof
5. adapter boundary hardening
6. real durable backend pilot
7. repo truth sync

Do not skip ahead to fake future systems.
