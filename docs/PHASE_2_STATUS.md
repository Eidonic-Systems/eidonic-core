# Phase 2 Status

This document is the current high-level status surface for Phase 2 work in Eidonic Core.

## Current architecture
The system now has:
- PostgreSQL-backed artifact persistence
- PostgreSQL-backed lineage persistence
- local Ollama provider support
- warmup and readiness surfaces
- persisted provider provenance
- persisted provider failure semantics
- plain-text response guard behavior
- narrow domain-task routing with fallback
- routing provenance
- governance policy surfaces
- governance eval surface
- governance provenance
- narrow governance enforcement pilot
- pinned governance baseline
- manifest-backed governance rules
- governance rule provenance

## Current control and routing position
Control model:
- `gemma3n:e4b`

Conditionally route-eligible candidate:
- `gemma3n:e2b`

Current routing truth:
- routing remains narrow and explicit
- control remains the default model
- candidate routing is limited and reversible
- routing provenance is persisted

## Governance status
Mirror Laws:
- explicit policy surface exists
- not yet fully runtime-enforced

Guardian Protocol:
- explicit policy surface exists
- not yet a full runtime Guardian engine

Governance runtime truth:
- normal safe orchestration persists `allow`
- provider failure persists `fallback`
- explicit impersonation-style requests persist `refuse`
- explicit materially ambiguous command input persists `hold`
- explicit scope-drift requests can persist `reshape`
- explicit human-review events can persist `handoff`

## Manifest-backed governance pilot
Governance pilot rules are now visible in:
- `config/governance_rules_manifest.json`

Current manifest-backed truth:
- rules are inspectable
- baseline-backed behavior remains pinned
- rule identity can now be persisted and retrieved

## What is not live yet
The repo does not yet have:
- a full Guardian runtime engine
- a broad governance rules engine
- generalized dynamic model routing
- wide enforcement scope beyond the narrow pilot
- full Mirror Laws enforcement

## Phase 2 discipline
The current build direction remains:
- narrow before broad
- provenance before opacity
- baseline before expansion
- explicit policy before enforcement
- reversible pilots before deep dependence

## Current truth
Phase 2 is no longer only scaffolding.

It now has a real operational spine:
- provider truth
- routing truth
- governance truth
- baseline-backed behavior
- visible manifest rules
- persisted rule provenance

## Dependency wave status update

The Phase 2 dependency wave has now been absorbed and proved on `main`.

Current proved dependency position:
- `httpx==0.28.1`
- `uvicorn==0.44.0`
- `fastapi==0.136.0`
- `pydantic==2.13.3`

Important truth:
- the isolated `pydantic` service batch was not the real blocker
- the real blocker was the shared editable package in `packages/common-schemas/python` still pinning the older `pydantic` version
- once the shared package and the four services were aligned, the dependency wave could be proved cleanly

Main proof after the dependency wave:
- `scripts/restart_phase_2_stack.ps1 -RunGate` passed
- `scripts/validate_governance_rules_manifest.ps1` passed
- `scripts/test_governance_rule_fixtures.ps1` passed


## Orchestration provenance invariant proof

- `scripts/validate_orchestration_provenance_invariants.ps1` proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces

## Orchestration provenance gate posture

- `scripts/validate_orchestration_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces


## Provider failure provenance invariant proof

- `scripts/validate_provider_failure_provenance_invariants.ps1` proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces

## Provider failure provenance gate posture

- `scripts/validate_provider_failure_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces


## Governance rule provenance invariant proof

- `scripts/validate_governance_rule_provenance_invariants.ps1` proves a real manifest-triggered governance path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces

## Governance rule provenance gate posture

- `scripts/validate_governance_rule_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a real manifest-triggered governance short-circuit path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces


## Routing fallback provenance invariant proof

- `scripts/validate_routing_fallback_provenance_invariants.ps1` proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces

## Routing fallback provenance gate posture

- `scripts/validate_routing_fallback_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces


## Routing candidate success provenance invariant proof

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces

## Routing candidate success provenance gate posture

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces


## Routing control nonrouteable provenance invariant proof

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces

## Routing control nonrouteable provenance gate posture

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces


## Governance rule matrix provenance invariant proof

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces

## Governance rule matrix provenance gate posture

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces


## Governance negative matrix provenance invariant proof

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces

## Governance negative matrix provenance gate posture

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces

## Runtime-proof stack discipline

- `scripts/validate_phase2_gate_surface_manifest.ps1` now declares the three-phase split between `validation_steps`, `startup_authority_steps`, and `post_start_runtime_steps`
- `scripts/start_phase_2_stack.ps1` remains the startup authority
- `scripts/run_phase2_gate.ps1` owns startup for full gate runs unless `-SkipStackStart` is used
- `scripts/run_declared_runtime_proof.ps1` now resolves allowed proof phases and only owns startup for `post_start_runtime_steps` unless `-SkipStackStart` is used
- operators should not manually call `scripts/start_phase_2_stack.ps1` before a gate wrapper that already owns startup

## Runtime-proof stack discipline validation

- `scripts/validate_automation_helpers.ps1` now validates the runtime-proof stack discipline surface through `config/automation_helper_surface_manifest.json`
- `scripts/run_declared_runtime_proof.ps1` must refuse undeclared scripts outside the allowed proof phases
- `scripts/run_governance_gate.ps1` must not reference `scripts/start_phase_2_stack.ps1`
- `scripts/run_governance_gate.ps1` must not carry the dead `SkipStackStart` parameter surface## Startup-authority gate phase posture

- `config/phase2_gate_surface_manifest.json` now declares `startup_authority_steps` as a dedicated gate phase
- `scripts/validate_runtime_stack_startup_idempotence.ps1` is now integrated there instead of being forced into the wrong phase
- the standard Phase 2 gate now proves startup-authority behavior before downstream post-start runtime proofs run

## Declared gate-phase proof helper posture

- `scripts/run_declared_runtime_proof.ps1` now resolves proofs across `startup_authority_steps` and `post_start_runtime_steps`
- startup-authority proofs do not receive a pre-start stack call from the helper
- post-start runtime proofs still receive one startup-authority call unless `-SkipStackStart` is used

## Declared gate-phase proof helper validation

- `scripts/validate_automation_helpers.ps1` now validates phase-aware helper behavior for `startup_authority_steps` and `post_start_runtime_steps`
- undeclared scripts outside the allowed proof phases must be refused

## Automation-helper surface manifest posture

- `config/automation_helper_surface_manifest.json` now declares the helper scripts and supporting surfaces covered by `scripts/validate_automation_helpers.ps1`
- the helper validator summary now reports the declared helper set instead of a stale hardcoded subset


