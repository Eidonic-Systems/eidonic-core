# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility

- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist orchestration artifact evidence in the local Phase 2 proof path
- persist matching artifact lineage evidence in the local Phase 2 proof path
- expose provider warmup and readiness behavior in the local Phase 2 proof path
- participate in provider, routing, governance, and state proof surfaces
- participate in startup, health, and gate discipline

## Truth classification

This document distinguishes:
- current runtime contract surfaces used by the local proof path
- declared validator and gate surfaces
- target posture that is not yet broad Guardian runtime behavior

The Orchestrator README must not be read as a claim that broad Guardian, broad routing, or broad governance enforcement is complete.

## Current phase

Phase 2 local orchestration service with PostgreSQL state discipline, local provider discipline, narrow routing proof surfaces, narrow governance proof surfaces, and explicit startup and gate verification.

## Current local runtime contract

The current local Phase 2 proof path exercises these Orchestrator-facing surfaces:

- `GET /health`
- `POST /provider/warm`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Current persistence posture

The local Phase 2 proof path validates:
- artifact record persistence behavior
- lineage record persistence behavior
- provider provenance fields on artifact and lineage records
- governance provenance fields on artifact and lineage records
- routing provenance fields on artifact and lineage records where routing is enabled

PostgreSQL remains the Phase 2 state target and proof-backed local posture.
Local JSON stores are fallback or scaffold surfaces only and should not be treated as the final state truth.

## Current provider surface

Current provider posture:
- local Ollama-backed provider path
- provider warmup surface
- provider readiness truth surface
- provider failure semantics
- plain-text response guard
- provider provenance validation through declared runtime proofs

Current local provider position:
- backend: `ollama`
- control model: `gemma3n:e4b`
- narrow route candidate: `gemma3n:e2b`

## Current governance surface

Current governance posture:
- Mirror Laws policy surface
- Guardian Protocol policy surface
- governance eval surface
- narrow manifest-backed governance enforcement pilot
- governance rule provenance validation
- governance change records
- governance change validation
- governance gate coverage

Manifest-backed governance outcomes currently carried by the narrow pilot:
- `allow`
- `fallback`
- `refuse`
- `hold`
- `reshape`
- `handoff`

This is not a full Guardian runtime engine.
It is a narrow, manifest-backed governance pilot with explicit proof surfaces.

## Current state surface

The Orchestrator participates in explicit Phase 2 state discipline:
- database bootstrap
- schema bootstrap
- schema drift validation
- startup-path state enforcement
- top-level gate state enforcement

Required PostgreSQL tables:
- `artifact_records`
- `artifact_lineage_records`

Schema validation checks expected provider, routing, governance, and rule-provenance fields on the persistence layer.

## Current proven local provider position

- backend: `ollama`
- control model: `gemma3n:e4b`
- narrow route candidate: `gemma3n:e2b`

## Current truth

The Orchestrator sits inside the stricter Phase 2 proof spine:
- explicit provider proof surfaces
- explicit routing proof surfaces
- explicit governance proof surfaces
- explicit state proof surfaces
- startup readiness verification
- fail-fast proof behavior

The public documentation should describe these as proof-backed local Phase 2 surfaces, not as broad completed runtime generalization.

## Provider readiness invariant proof

- `scripts/validate_provider_readiness_invariants.ps1` proves `POST /provider/warm` and `GET /health` agree on provider-ready truth across repeated warmup.

## Orchestration provenance invariant proof

- `scripts/validate_orchestration_provenance_invariants.ps1` proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces.

## Provider failure provenance invariant proof

- `scripts/validate_provider_failure_provenance_invariants.ps1` proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces.

## Governance rule provenance invariant proof

- `scripts/validate_governance_rule_provenance_invariants.ps1` proves a real manifest-triggered governance path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces.

## Routing fallback provenance invariant proof

- `scripts/validate_routing_fallback_provenance_invariants.ps1` proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces.

## Routing candidate success provenance invariant proof

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces.

## Routing control nonrouteable provenance invariant proof

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces.

## Governance rule matrix provenance invariant proof

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces.

## Governance negative matrix provenance invariant proof

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces.

## Gate-integrated proof posture

The relevant runtime proof scripts are declared in:
- `config/phase2_gate_surface_manifest.json`

Post-start runtime proofs live under:
- `post_start_runtime_steps`

That means these proofs run after static validation, startup-authority proof, state checks, provider warmup, and baseline health checks.

