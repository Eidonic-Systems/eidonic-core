# Eidonic Core

Eidonic Core is the current system repository for the Phase 2 build.

It is no longer only scaffolding.
The repo now has a real operational spine built around:
- provider truth
- routing truth
- governance truth
- state truth
- pinned baselines
- visible manifest rules
- persisted provenance
- explicit startup and gate discipline

## Current Phase 2 position

### Persistence and state discipline
- PostgreSQL-backed artifact persistence
- PostgreSQL-backed lineage persistence
- PostgreSQL database bootstrap
- PostgreSQL schema bootstrap
- PostgreSQL schema drift validation
- top-level gate enforcement for state bootstrap and schema validation
- startup-path enforcement for state bootstrap and schema validation

### Provider discipline
- local Ollama-backed provider support
- provider warmup and readiness surfaces
- persisted provider provenance
- persisted provider failure semantics
- plain-text response guard behavior

### Model and routing discipline
- Gemma-family model policy
- model decision index and decision records
- generic eval and baseline
- domain-task eval and baseline
- candidate comparison surfaces
- runtime profile surfaces
- narrow domain-task routing with fallback
- persisted routing provenance

### Governance discipline
- Mirror Laws policy surface
- Guardian Protocol policy surface
- governance eval surface
- governance provenance surface
- narrow governance enforcement pilot
- governance eval baseline
- manifest-backed governance rules
- governance rule provenance surface
- governance change records
- governance change validation
- governance gate

### Startup and proof discipline
- startup preflight
- startup state bootstrap
- startup readiness checks
- top-level Phase 2 gate
- fail-fast gate behavior
- self-hosted CI mirror for the Phase 2 gate
- host bootstrap checks
- service venv bootstrap
- PostgreSQL bootstrap surfaces
- laptop runner sync surface
- stack restart surface

## Current control and routing truth
Control model:
- `gemma3n:e4b`

Conditionally route-eligible candidate:
- `gemma3n:e2b`

Current routing truth:
- control remains the default model
- routing remains narrow and explicit
- candidate routing is limited and reversible
- routing provenance is persisted

## Current governance truth
The repo now has:
- explicit governance policy
- explicit governance evaluation
- explicit governance provenance
- narrow manifest-backed enforcement
- pinned governance baseline
- pinned governance manifest baseline
- persisted rule identity and manifest version
- governance change records
- governance change validation

Current enforced governance outcomes:
- `allow`
- `fallback`
- `refuse`
- `hold`
- `reshape`
- `handoff`

This is still not a full Guardian runtime engine.
It is a narrow, auditable governance pilot with real proof surfaces.

## Current state truth
The Phase 2 state spine is now explicit:
- database bootstrap
- schema bootstrap
- schema drift validation
- required state checks inside startup
- required state checks inside the top-level gate

That means persistence is no longer relying only on incidental side effects.

## Authoritative status surfaces
Start here for current repo truth:
- `docs/PHASE_2_STATUS.md`
- `docs/PHASE_2_MILESTONE_100_MERGED_PRS.md`
- `services/eidon-orchestrator/README.md`

Governance and state surfaces:
- `docs/PHASE_2_GOVERNANCE_GATE_SURFACE.md`
- `docs/PHASE_2_STATE_GATE_SURFACE.md`
- `docs/PHASE_2_POSTGRES_BOOTSTRAP_SURFACE.md`
- `docs/PHASE_2_POSTGRES_SCHEMA_BOOTSTRAP_SURFACE.md`
- `docs/PHASE_2_POSTGRES_SCHEMA_DRIFT_SURFACE.md`
- `docs/PHASE_2_STARTUP_STATE_BOOTSTRAP_SURFACE.md`
- `docs/PHASE_2_STARTUP_READINESS_SURFACE.md`
- `docs/PHASE_2_STACK_RESTART_SURFACE.md`
- `docs/RUNNER_BOOTSTRAP.md`

## What is not live yet
The repo does not yet have:
- a full Guardian runtime engine
- generalized dynamic routing
- broad governance enforcement beyond the narrow pilot
- full Mirror Laws runtime enforcement

## Build discipline
The repo direction remains:
- narrow before broad
- provenance before opacity
- baseline before expansion
- explicit policy before enforcement
- reversible pilots before dependence
- state truth before convenience

## Current truth
Eidonic Core is now a disciplined local orchestration build with:
- persisted provider truth
- persisted routing truth
- persisted governance truth
- explicit state truth
- baseline-backed behavior
- visible rules
- explicit rule provenance
- fail-fast startup and gate discipline
