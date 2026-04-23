# Eidon Orchestrator

The Eidon Orchestrator is the current orchestration service for Eidonic Core.

## Responsibility
- receive a session-bound orchestration request
- produce the current orchestration outcome
- persist an orchestration artifact record
- persist a matching artifact lineage record
- record provider provenance and provider failure truth
- record governance provenance
- expose provider warmup and readiness surfaces
- expose retrieval surfaces for persisted records
- participate in the current startup, state, and gate discipline

## Current phase
Phase 2 PostgreSQL-backed orchestration service with local provider discipline, narrow routing, narrow governance enforcement, and explicit state bootstrap verification.

## Current endpoints
- `GET /health`
- `POST /provider/warm`
- `POST /orchestrate`
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Current persistence
- artifact records persisted in PostgreSQL
- lineage records persisted in PostgreSQL
- local JSON stores remain fallback only

## Current provider surface
- provider adapter contract
- local Ollama-backed provider
- persisted provider provenance
- persisted provider failure semantics
- explicit warmup surface
- explicit readiness truth
- plain-text response guard
- narrow domain-task routing pilot
- persisted routing provenance

## Current governance surface
- Mirror Laws policy surface
- Guardian Protocol policy surface
- governance eval surface
- persisted governance provenance
- narrow governance enforcement pilot
- pinned governance baseline
- manifest-backed governance rules
- persisted governance rule provenance
- governance change records
- governance change validation
- governance gate coverage

## Current state surface
The Orchestrator now participates in an explicit Postgres state discipline:
- database bootstrap
- schema bootstrap
- schema drift validation
- startup-path state enforcement
- top-level gate state enforcement

Required PostgreSQL tables:
- `artifact_records`
- `artifact_lineage_records`

Required schema validation now checks the expected provider, routing, governance, and rule-provenance fields on both tables.

## Persisted provider provenance
Artifact records persist:
- `provider_backend`
- `provider_model`
- `provider_status`
- `provider_route_mode`
- `provider_route_reason`
- `provider_error_code`
- `provider_error_message`

Lineage records persist:
- `artifact_provider_backend`
- `artifact_provider_model`
- `artifact_provider_status`
- `artifact_provider_route_mode`
- `artifact_provider_route_reason`
- `artifact_provider_error_code`
- `artifact_provider_error_message`

## Persisted governance provenance
Artifact records persist:
- `governance_outcome`
- `governance_reason`
- `governance_rule_id`
- `governance_manifest_version`

Lineage records persist:
- `artifact_governance_outcome`
- `artifact_governance_reason`
- `artifact_governance_rule_id`
- `artifact_governance_manifest_version`

## Warmup and readiness
- `POST /provider/warm` warms the selected provider
- `GET /health` exposes provider readiness truth
- `scripts/warm_eidon_provider.ps1` provides a direct warmup entry point
- `scripts/start_phase_2_stack.ps1` now verifies startup readiness before provider warmup completes

## Failure semantics
The current provider layer distinguishes:
- `provider_unavailable`
- `provider_timeout`
- `provider_model_missing`
- `provider_empty_response`
- `provider_http_error`

When provider generation fails, Orchestrator persists a `provider_failed` artifact and matching lineage record instead of collapsing the event into vague server failure.

## Domain-task routing pilot
The current routing pilot remains narrow and optional.

Environment flags:
- `EIDON_DOMAIN_ROUTING_ENABLED`
- `EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL`

Pilot rules:
- control model remains `EIDON_PROVIDER_MODEL`
- only a small allowlist of domain-task patterns is route-eligible
- candidate failure falls back to the control model
- the chosen model is reflected in persisted provenance

## Governance enforcement pilot
The current governance enforcement pilot remains narrow and explicit.

Current enforced outcomes:
- `allow`
- `fallback`
- `refuse`
- `hold`
- `reshape`
- `handoff`

Current truth:
- normal safe orchestration persists `allow`
- provider failure persists `fallback`
- explicit impersonation-style requests persist `refuse`
- explicit materially ambiguous command input persists `hold`
- explicit scope-drift requests can persist `reshape`
- explicit human-review events can persist `handoff`

## Governance rules manifest
The narrow governance pilot rules are loaded from:
- `config/governance_rules_manifest.json`

The manifest currently defines:
- manifest version
- default success behavior
- explicit rule ids
- match patterns
- governance outcomes
- governance reasons
- response text

## Current proven local provider position
- backend: `ollama`
- control model: `gemma3n:e4b`
- narrow route candidate: `gemma3n:e2b`

## Current truth
The Orchestrator now sits inside a stricter Phase 2 spine:
- explicit provider truth
- explicit routing truth
- explicit governance truth
- explicit state truth
- startup readiness verification
- fail-fast proof behavior

## Provider readiness invariant proof

- `scripts/validate_provider_readiness_invariants.ps1` proves `POST /provider/warm` and `GET /health` agree on provider-ready truth across repeated warmup

## Orchestration provenance invariant proof

- `scripts/validate_orchestration_provenance_invariants.ps1` proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces

## Gate-integrated provenance proof

- `scripts/validate_orchestration_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces


## Provider failure provenance invariant proof

- `scripts/validate_provider_failure_provenance_invariants.ps1` proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces

## Gate-integrated failure provenance proof

- `scripts/validate_provider_failure_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces


## Governance rule provenance invariant proof

- `scripts/validate_governance_rule_provenance_invariants.ps1` proves a real manifest-triggered governance path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces

## Gate-integrated governance rule provenance proof

- `scripts/validate_governance_rule_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a real manifest-triggered governance short-circuit path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces


## Routing fallback provenance invariant proof

- `scripts/validate_routing_fallback_provenance_invariants.ps1` proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces

## Gate-integrated routing fallback provenance proof

- `scripts/validate_routing_fallback_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces


## Routing candidate success provenance invariant proof

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces

## Gate-integrated routing candidate success provenance proof

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces


## Routing control nonrouteable provenance invariant proof

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces

## Gate-integrated routing control nonrouteable provenance proof

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces


## Governance rule matrix provenance invariant proof

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces

## Gate-integrated governance rule matrix provenance proof

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces


## Governance negative matrix provenance invariant proof

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces

## Gate-integrated governance negative matrix provenance proof

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces

