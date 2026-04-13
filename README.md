# Eidonic Core

Eidonic Core is the current system repository for the Phase 2 build.

It is no longer only scaffolding.
The repo now contains a real operational spine built around:
- provider truth
- routing truth
- governance truth
- pinned baselines
- visible manifest rules
- persisted provenance

## Current Phase 2 position
The current build includes:

### Persistence and service backbone
- PostgreSQL-backed artifact persistence
- PostgreSQL-backed lineage persistence
- Phase 2 Orchestrator service surfaces
- health, warmup, orchestration, artifact, and lineage endpoints

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
- persisted rule identity and manifest version

Current enforced governance outcomes:
- `allow`
- `fallback`
- `refuse`
- `hold`

This is not yet a full Guardian runtime engine.
It is a narrow, auditable governance pilot.

## Authoritative status surfaces
Start here for current repo truth:
- `docs/PHASE_2_STATUS.md`
- `docs/PHASE_2_MILESTONE_100_MERGED_PRS.md`
- `services/eidon-orchestrator/README.md`

Model and policy surfaces:
- `docs/MODEL_DECISION_INDEX.md`
- `docs/GEMMA_FAMILY_MODEL_POLICY.md`
- `docs/GEMMA_ROUTING_POLICY.md`
- `docs/MIRROR_LAWS_POLICY.md`
- `docs/GUARDIAN_PROTOCOL_POLICY.md`

Governance and routing surfaces:
- `docs/PHASE_2_GOVERNANCE_EVAL_SURFACE.md`
- `docs/PHASE_2_GOVERNANCE_PROVENANCE_SURFACE.md`
- `docs/PHASE_2_GOVERNANCE_ENFORCEMENT_PILOT_SURFACE.md`
- `docs/PHASE_2_GOVERNANCE_EVAL_BASELINE.md`
- `docs/PHASE_2_GOVERNANCE_RULES_MANIFEST_SURFACE.md`
- `docs/PHASE_2_GOVERNANCE_RULE_PROVENANCE_SURFACE.md`
- `docs/PHASE_2_DOMAIN_TASK_ROUTING_PILOT_SURFACE.md`
- `docs/PHASE_2_DOMAIN_TASK_ROUTING_PROVENANCE_SURFACE.md`

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

## Current truth
Eidonic Core is now a disciplined local orchestration build with:
- persisted provider truth
- persisted routing truth
- persisted governance truth
- baseline-backed behavior
- visible rules
- explicit rule provenance
