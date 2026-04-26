# Project State at a Glance

## Current phase

Phase 2 build solidification, trust-surface hardening, and Codex operating-surface setup.

## Current truth classification posture

Public docs should distinguish:
- live repo surfaces
- local operator-proved surfaces
- declared validation surfaces
- target posture

External-facing docs must not claim broad runtime behavior as complete unless current repo code or a proved local gate/validator path supports it.

## Current runtime spine

`signal-gateway -> herald-service -> session-engine -> eidon-orchestrator`

## Current service topology truth

Declared in:
- `config/service_topology_manifest.json`

Current ports:
- `signal-gateway` -> `8000`
- `session-engine` -> `8001`
- `herald-service` -> `8002`
- `eidon-orchestrator` -> `8003`

## Current dependency truth

Declared in:
- `config/phase2_python_dependency_truth.json`

Current shared critical pin:
- `pydantic==2.13.3` across the four Phase 2 services and `packages/common-schemas/python`

## Current gate posture

Gate entry:
- `scripts/run_phase2_gate.ps1`

Gate validation truth source:
- `config/phase2_gate_surface_manifest.json`

Gate manifest validator:
- `scripts/validate_phase2_gate_surface_manifest.ps1`

The gate consumes declared pre-start validation order from `validation_steps`, then consumes startup-authority proof order from `startup_authority_steps`, then consumes post-start runtime validation order from `post_start_runtime_steps` after startup-authority proof, state checks, warmup, and health.

## Current governance posture

Declared in:
- `config/governance_rules_manifest.json`
- validator and fixture coverage under `scripts/`

## Current runner posture

- self-hosted Windows runner
- workflow: `.github/workflows/phase2-gate.yml`
- trust contract: `docs/PHASE_2_RUNNER_TRUST_CONTRACT.md`

## Current repo-memory surfaces

- `AGENTS.md`
- `.codex/config.toml`
- `.agents/skills/phase2-branch-flow/SKILL.md`
- `.agents/skills/phase2-dependency-wave/SKILL.md`
- `docs/CODEX_WORKFLOW.md`
- `docs/PROJECT_STATE_AT_A_GLANCE.md`
- `docs/SESSION_LOG.md`

## Current operating rules

- one bounded branch at a time
- update local after every merge
- prove the branch before claiming it done
- document branch work inside the repo
- prefer one declared truth source per control surface

## Current open hardening direction

Keep reducing duplicated truth and turn recurring manual workflows into bounded, documented, repo-carried operating surfaces.

## Current branch automation surfaces

- `scripts/start_bounded_branch.ps1`
- `scripts/finish_merged_branch.ps1`
- `scripts/run_phase2_gate_with_capture.ps1`
- `scripts/append_session_log_entry.ps1`

## Current dependency-wave automation surface

- `scripts/absorb_phase2_dependency_wave.ps1`

## Current automation helper validation surface

- `scripts/validate_automation_helper_surface_manifest.ps1`
- scripts/validate_automation_helpers.ps1`r

## Current temp-file hygiene surface

- `.gitignore` ignores local proof artifact files
- `scripts/finish_merged_branch.ps1` pre-cleans known temp output files before dirty-tree refusal

## Current cleanup idempotence posture

- `scripts/finish_merged_branch.ps1` treats an already-absent local branch as an idempotent cleanup outcome

## Current temp-hygiene validation posture

- `scripts/validate_automation_helpers.ps1` proves ignored local proof artifacts do not change git status
- `scripts/validate_automation_helpers.ps1` proves merged-branch cleanup still includes temp-file pre-clean behavior

## Current workflow validation surface

- `scripts/validate_phase2_workflow_surface.ps1` validates `.github/workflows/phase2-gate.yml`
- gate inclusion order is declared in `config/phase2_gate_surface_manifest.json`

## Current capture-wrapper output posture

- `scripts/run_phase2_gate_with_capture.ps1` uses a unique default local gate-output path per run
- `.gitignore` and cleanup hygiene cover wildcard gate-output temp artifacts

## Current Codex validation surface

- `scripts/validate_codex_surfaces.ps1` validates `AGENTS.md`, `.codex/config.toml`, repo skill manifests, and Codex recovery docs
- gate inclusion order is declared in `config/phase2_gate_surface_manifest.json`

## Current project-state validation surface

- `scripts/validate_project_state_surface.ps1` validates `docs/PROJECT_STATE_AT_A_GLANCE.md` against the declared repo truth surfaces it should reference

## Current session-log validation surface

- `scripts/validate_session_log_surface.ps1` validates `docs/SESSION_LOG.md` as a repo recovery surface

## Current recovery-surface truth source

- `config/recovery_surface_manifest.json` declares the repo recovery-surface references
- `scripts/validate_recovery_surface_manifest.ps1` validates that truth source
- recovery docs should point to that manifest instead of retyping the full recovery-surface list in prose

## Current untracked-file guard surface

- `scripts/validate_untracked_repo_files.ps1` detects untracked files before final proof and commit
- known temp artifacts stay excluded through git ignore rules

## Current scripts-readme validation surface

- `scripts/validate_scripts_readme_surface.ps1` validates `scripts/README.md` against the declared recovery-surface truth source

## Current operator-surface gate posture

- `config/phase2_gate_surface_manifest.json` declares operator-surface gate integration
- the standard Phase 2 gate now validates project-state, session-log, untracked-file, scripts-README, root-doc, and authoritative-status surfaces before downstream runtime checks

## Current root-doc validation surface

- `scripts/validate_root_doc_surfaces.ps1` validates `README.md` and `SECURITY.md` against the declared recovery-surface truth source

## Current root-doc gate posture

- `scripts/validate_root_doc_surfaces.ps1` is included in `config/phase2_gate_surface_manifest.json`
- the standard Phase 2 gate now validates `README.md` and `SECURITY.md` before downstream runtime checks

## Current authoritative-status validation surface

- `scripts/validate_authoritative_status_surfaces.ps1` validates the authoritative status surfaces declared in `README.md` against the recovery-surface truth source

## Current PostgreSQL bootstrap idempotence surface

- `scripts/validate_phase2_postgres_bootstrap_idempotence.ps1` proves repeated database bootstrap, repeated schema bootstrap, and post-repeat schema-drift validation stay clean on the local Phase 2 state layer

## Current PostgreSQL state gate posture

- `scripts/validate_phase2_postgres_bootstrap_idempotence.ps1` is included in `config/phase2_gate_surface_manifest.json`
- the standard Phase 2 gate now proves repeated local PostgreSQL bootstrap behavior before downstream runtime checks

## Current provider readiness invariant surface

- `scripts/validate_provider_readiness_invariants.ps1` proves the warmup and health surfaces agree on provider-ready truth across repeated warmup

## Current provider readiness gate posture

- `scripts/validate_provider_readiness_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves warmup and health agreement after startup and baseline health checks


## Current orchestration provenance invariant surface

- `scripts/validate_orchestration_provenance_invariants.ps1` proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces

## Current orchestration provenance gate posture

- `scripts/validate_orchestration_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces


## Current provider failure provenance invariant surface

- `scripts/validate_provider_failure_provenance_invariants.ps1` proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces

## Current provider failure provenance gate posture

- `scripts/validate_provider_failure_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces


## Current governance rule provenance invariant surface

- `scripts/validate_governance_rule_provenance_invariants.ps1` proves a real manifest-triggered governance path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces

## Current governance rule provenance gate posture

- `scripts/validate_governance_rule_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a real manifest-triggered governance short-circuit path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces


## Current routing fallback provenance invariant surface

- `scripts/validate_routing_fallback_provenance_invariants.ps1` proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces

## Current routing fallback provenance gate posture

- `scripts/validate_routing_fallback_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces


## Current routing candidate success provenance invariant surface

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces

## Current routing candidate success provenance gate posture

- `scripts/validate_routing_candidate_success_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces


## Current routing control nonrouteable provenance invariant surface

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces

## Current routing control nonrouteable provenance gate posture

- `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces


## Current governance rule matrix provenance invariant surface

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces

## Current governance rule matrix provenance gate posture

- `scripts/validate_governance_rule_matrix_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves the enabled manifest-backed governance short-circuit rule matrix persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces


## Current governance negative matrix provenance invariant surface

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces

## Current governance negative matrix provenance gate posture

- `scripts/validate_governance_negative_matrix_provenance_invariants.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `post_start_runtime_steps`
- the standard Phase 2 gate now proves the negative governance fixture matrix falls through to normal orchestration and persists matching default-success governance provenance across artifact and lineage retrieval surfaces

## Current runtime-proof stack discipline posture

- static validators belong to `validation_steps`
- live endpoint proofs belong to `post_start_runtime_steps`
- `scripts/start_phase_2_stack.ps1` is the single startup authority
- `scripts/run_phase2_gate.ps1` owns startup for full gate runs unless `-SkipStackStart` is used
- `scripts/run_declared_runtime_proof.ps1` is phase-aware and only owns startup for manual `post_start_runtime_steps` runs unless `-SkipStackStart` is used

## Current runtime-proof stack discipline validation posture

- `scripts/validate_automation_helpers.ps1` validates the runtime-proof stack discipline helper surface
- undeclared runtime-proof scripts must be refused
- `scripts/run_governance_gate.ps1` must remain free of direct startup ownership

## Current runtime stack startup idempotence posture

- `scripts/start_phase_2_stack.ps1` reuses an already-healthy declared stack
- repeated startup is expected to avoid duplicate service-window launches
- `scripts/validate_runtime_stack_startup_idempotence.ps1` proves the second startup run reuses the declared stack instead of starting services again

## Current startup-authority gate posture

- `config/phase2_gate_surface_manifest.json` now declares `startup_authority_steps`
- startup-authority proofs run between static validation and post-start runtime proofs
- `scripts/validate_runtime_stack_startup_idempotence.ps1` now lives in that startup-authority phase

## Current declared gate-phase proof helper posture

- `scripts/run_declared_runtime_proof.ps1` can resolve declared proofs from `startup_authority_steps` and `post_start_runtime_steps`
- startup-authority proofs are run without a pre-start stack call from the helper
- post-start runtime proofs still receive one startup-authority call unless `-SkipStackStart` is used

## Current automation-helper surface truth source

- `config/automation_helper_surface_manifest.json` declares the helper scripts and supporting surfaces covered by `scripts/validate_automation_helpers.ps1`
- helper coverage reporting should come from that manifest instead of hardcoded validator lists

## Current automation-helper surface manifest validation posture

- `scripts/validate_automation_helper_surface_manifest.ps1` validates `config/automation_helper_surface_manifest.json` directly
- automation-helper manifest drift should fail at the manifest surface before broader helper validation runs

## Current automation-helper surface manifest gate posture

- `scripts/validate_automation_helper_surface_manifest.ps1` is declared in `config/phase2_gate_surface_manifest.json` under `validation_steps` immediately before `scripts/validate_automation_helpers.ps1`
- the standard Phase 2 gate now validates the automation-helper surface manifest before broader helper validation runs

## Current automation-helper manifest precheck duplication control posture

- standalone `scripts/validate_automation_helpers.ps1` runs still precheck the manifest validator first by default
- gate runs now skip that internal precheck only when upstream validation order already proved the manifest earlier in `validation_steps`

## Current next operational branch

Recommended next branch:
- `phase-2/codex-first-repetitive-alignment-trial`

Purpose:
- prove Codex CLI can inspect repo-carried truth surfaces without editing files
- verify Codex follows `AGENTS.md`, Codex workflow guidance, and task-template constraints
- use the result to decide whether Codex can safely handle bounded repetitive alignment work

Next expected branch after this trial:
- `phase-2/codex-assisted-repetitive-doc-alignment`

