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
