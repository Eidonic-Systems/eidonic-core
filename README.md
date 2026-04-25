# Eidonic Core

Eidonic Core is the current system repository for the Phase 2 build.

It is no longer only scaffolding, but it is also not a finished autonomous Guardian runtime.

The current repo posture is best understood as a disciplined local orchestration build with:
- explicit service topology
- manifest-backed validation order
- startup and gate discipline
- PostgreSQL state bootstrap and schema validation surfaces
- local Ollama provider support in the operator proof path
- narrow routing and governance proof surfaces
- persisted provenance proof surfaces validated by declared scripts
- recovery and operator-surface validation

## Truth classification

This repo distinguishes:

- **live repo surfaces**: files, manifests, scripts, schemas, and docs present in `main`
- **local operator-proved surfaces**: behavior proved by local startup, gate, or validator runs
- **declared validation surfaces**: scripts and manifests that define the proof path
- **target posture**: intended future runtime behavior not yet generalized or broadly enforced

When those conflict, current repo code, manifests, and proved command paths win.

## Current Phase 2 position

### Persistence and state discipline

Current local proof posture includes:
- PostgreSQL database bootstrap
- PostgreSQL schema bootstrap
- PostgreSQL schema drift validation
- repeated PostgreSQL bootstrap idempotence validation
- startup-path enforcement for state bootstrap and schema validation
- top-level gate enforcement for state bootstrap and schema validation

The local Phase 2 proof path validates artifact and lineage persistence behavior through declared runtime proof scripts.

### Provider discipline

Current local proof posture includes:
- local Ollama-backed provider support
- provider warmup and readiness proof surfaces
- provider failure semantics proof surfaces
- plain-text response guard behavior
- provider provenance validation through declared post-start runtime proofs

### Model and routing discipline

Current control model:
- `gemma3n:e4b`

Current narrow route candidate:
- `gemma3n:e2b`

Current routing posture:
- control remains the default model
- routing remains narrow and explicit
- candidate routing is limited and reversible
- routing provenance is validated through declared post-start runtime proofs

### Governance discipline

Current governance posture includes:
- Mirror Laws policy surface
- Guardian Protocol policy surface
- governance eval surface
- narrow manifest-backed governance enforcement pilot
- pinned governance baseline
- governance change records
- governance change validation
- governance gate coverage
- governance provenance validation through declared post-start runtime proofs

Current enforced governance outcomes:
- `allow`
- `fallback`
- `refuse`
- `hold`
- `reshape`
- `handoff`

This is still not a full Guardian runtime engine.
It is a narrow, auditable governance pilot with real proof surfaces.

### Startup and proof discipline

Current startup and proof posture includes:
- startup preflight
- startup state bootstrap
- startup readiness checks
- top-level Phase 2 gate
- fail-fast gate behavior
- self-hosted CI mirror for the Phase 2 gate
- host bootstrap checks
- service venv bootstrap
- PostgreSQL bootstrap surfaces
- stack restart surface
- three-phase gate shape through `config/phase2_gate_surface_manifest.json`

## Current gate and recovery truth sources

Gate entry:
- `scripts/run_phase2_gate.ps1`

Gate truth source:
- `config/phase2_gate_surface_manifest.json`

Recovery truth source:
- `config/recovery_surface_manifest.json`

Automation-helper truth source:
- `config/automation_helper_surface_manifest.json`

Service topology truth source:
- `config/service_topology_manifest.json`

Governance truth source:
- `config/governance_rules_manifest.json`

Dependency truth source:
- `config/phase2_python_dependency_truth.json`

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

Operator recovery surfaces:
- `SECURITY.md`
- `docs/PROJECT_STATE_AT_A_GLANCE.md`
- `docs/SESSION_LOG.md`

## What is not live yet

The repo does not yet have:
- a full Guardian runtime engine
- generalized dynamic routing
- broad governance enforcement beyond the narrow pilot
- full Mirror Laws runtime enforcement
- an autonomous agent swarm
- unsupervised self-modifying runtime behavior

## Build discipline

The repo direction remains:
- narrow before broad
- provenance before opacity
- baseline before expansion
- explicit policy before enforcement
- reversible pilots before dependence
- state truth before convenience
- proof before public claims

## Current truth

Eidonic Core is now a disciplined local Phase 2 orchestration build with manifest-backed startup, gate, recovery, automation-helper, provider, routing, governance, and state proof surfaces.

The next required discipline is public truth reconciliation: docs must describe what the current repo proves, not what the build intends to become later.
