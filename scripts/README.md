# Scripts

This directory holds local helper scripts for running and testing the Eidonic Core build.

## validate_service_topology_manifest.ps1

Validates the structure and runtime viability of `config/service_topology_manifest.json`.

Checks include:
- required manifest fields
- duplicate service names
- duplicate ports
- health URL and port alignment
- startup command and port alignment
- required service paths exist

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_service_topology_manifest.ps1
```

## validate_phase2_dependency_pins.ps1

Validates the bounded dependency reproducibility posture for the current Phase 2 Python services.

Dependency truth source:
- `config/phase2_python_dependency_truth.json`

Checks include:
- exact direct `==` pins in each Phase 2 service `requirements.txt`
- exactly one editable local `common-schemas` reference per service
- expected shared dependency pins in `packages/common-schemas/python/pyproject.toml`

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_dependency_pins.ps1
```

## start_phase_2_stack.ps1

Starts four new PowerShell windows for the current local Phase 2 stack using `config/service_topology_manifest.json` as the topology truth source.

Current manifest-backed ports:
- `signal-gateway` on port 8000
- `session-engine` on port 8001
- `herald-service` on port 8002
- `eidon-orchestrator` on port 8003

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1
```

## validate_phase2_topology_consistency.ps1

Validates that the current topology truth surfaces stay aligned:
- `config/service_topology_manifest.json`
- `.env.example`
- `tests/README.md`
- `scripts/start_phase_2_stack.ps1`
- `scripts/README.md`
- `services/signal-gateway/app/main.py`
- `tests/integration/test_full_chain.ps1`

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_topology_consistency.ps1
```

## run_phase2_gate.ps1

Runs the current Phase 2 gate using `config/phase2_gate_surface_manifest.json` as the validation-order truth source before downstream runtime checks.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1
```

## pin_phase2_python_dependencies.ps1

Pins still-floating direct Python service dependencies to exact versions using the current local service virtual environments as the source of truth.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pin_phase2_python_dependencies.ps1
```

## test_phase_1_core_loop.ps1

Runs the earlier Phase 1 core loop checks against locally running services.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test_phase_1_core_loop.ps1
```

## start_bounded_branch.ps1

Automates the standard start-of-branch flow from clean `main`.

Supports:
- switching to `main`
- pulling fast-forward only
- pruning remotes
- status check
- bounded branch creation
- dry-run preview mode

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_bounded_branch.ps1 -BranchName phase-2/example-branch
```

## finish_merged_branch.ps1

Automates the standard post-merge local cleanup flow.

Supports:
- switching to `main`
- pulling fast-forward only
- pruning remotes
- temp output cleanup
- local branch deletion
- dry-run preview mode

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finish_merged_branch.ps1 -BranchName phase-2/example-branch
```

## run_phase2_gate_with_capture.ps1

Runs the Phase 2 gate and captures output to a file, with optional `-SkipStackStart` and dry-run preview mode.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate_with_capture.ps1
```

## append_session_log_entry.ps1

Appends a standard branch-scoped entry to `docs/SESSION_LOG.md` and supports dry-run preview mode.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\append_session_log_entry.ps1 -BranchName phase-2/example-branch -NotesText "Did the thing."
```

## sync_phase2_dependency_truth.ps1

Syncs the current Phase 2 Python dependency surfaces from the declared truth source in `config/phase2_python_dependency_truth.json`.

Supports:
- rewriting each Phase 2 service `requirements.txt` from the truth file
- rewriting the shared package dependency block in `packages/common-schemas/python/pyproject.toml` from the truth file
- dry-run preview mode

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync_phase2_dependency_truth.ps1
```

## absorb_phase2_dependency_wave.ps1

Automates a bounded dependency-wave absorption flow for the current Phase 2 Python dependency truth source.

Supports:
- updating one approved package version in `config/phase2_python_dependency_truth.json`
- syncing dependent files from the truth source
- running dependency pin validation
- optionally running the Phase 2 gate with capture
- optionally appending a session-log entry
- dry-run preview mode

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\absorb_phase2_dependency_wave.ps1 -PackageName pydantic -NewVersion 2.13.3 -ExpectedCurrentVersion 2.13.3 -DryRun
```

## Automation helper hardening note

The automation helpers are expected to be idempotent and fail early on dirty working trees.

Current hardening expectations:
- `finish_merged_branch.ps1` must refuse cleanup before pull if the working tree is dirty
- `sync_phase2_dependency_truth.ps1` must not rewrite already aligned files
- `absorb_phase2_dependency_wave.ps1` must not dirty the dependency truth file on a no-op approved version path
- `append_session_log_entry.ps1` should accept multiple note arguments cleanly through `powershell -File`

## validate_automation_helpers.ps1

Validates the local workflow automation helper layer for bounded branch flow, merged-branch cleanup, gate capture, session-log append behavior, dependency truth sync, and no-op dependency-wave idempotence.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_automation_helpers.ps1
```

## Workflow gate capture note

The GitHub Actions Phase 2 workflow now runs `scripts/run_phase2_gate_with_capture.ps1` and uploads the captured gate output as a workflow artifact.

This keeps failure output reviewable without depending on raw step log reconstruction alone.

## Temp file hygiene note

Known local proof artifacts are ignored by git and pre-cleaned by `scripts/finish_merged_branch.ps1` before dirty-tree refusal.

Current local proof artifact patterns:
- `tmp_phase2_gate_output*.txt`
- `tmp_test_full_chain_output*.txt`

## Cleanup idempotence note

`scripts/finish_merged_branch.ps1` now treats an already-absent local branch as a clean outcome instead of a cleanup failure.

## Temp hygiene validation note

`scripts/validate_automation_helpers.ps1` now proves that local proof artifact files stay ignored by git and that merged-branch cleanup still advertises temp-file pre-clean behavior.

## validate_phase2_workflow_surface.ps1

Validates the current `.github/workflows/phase2-gate.yml` surface for the repo posture the gate now depends on.

Checks include:
- workflow_dispatch-only trigger posture
- minimal `contents: read` permission surface
- self-hosted Windows runner label set including `eidonic-phase2`
- pinned `actions/checkout` commit SHA
- use of `scripts/run_phase2_gate_with_capture.ps1`
- upload of captured gate output artifact
- `if: always()` on artifact upload

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_workflow_surface.ps1
```

## Capture-wrapper output hardening note

`scripts/run_phase2_gate_with_capture.ps1` now uses a unique default local output path for each run, and cleanup/temp-hygiene surfaces now cover wildcard gate-output artifacts.

## validate_codex_surfaces.ps1

Validates the repo-carried Codex operating surfaces, including `AGENTS.md`, project-scoped Codex config, repo skill manifests, Codex workflow documentation, and project-state recovery documentation.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_codex_surfaces.ps1
```

## validate_phase2_gate_surface_manifest.ps1

Validates the declared Phase 2 gate validation truth source at `config/phase2_gate_surface_manifest.json`.

Checks include:
- manifest version presence
- non-empty validation step list
- unique validation labels
- unique validation script paths
- validation script paths resolve to PowerShell scripts under `scripts/`
- validation scripts exist on disk

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_gate_surface_manifest.ps1
```

## Gate surface truth source note

The Phase 2 validation order is now declared in `config/phase2_gate_surface_manifest.json` and consumed by `scripts/run_phase2_gate.ps1` instead of being retyped only inside the gate script.

## Gate documentation rule

`config/phase2_gate_surface_manifest.json` is the declared truth source for gate validation order.

This README should reference that manifest instead of manually restating the full gate validation sequence in prose.

## validate_project_state_surface.ps1

Validates `docs/PROJECT_STATE_AT_A_GLANCE.md` against the declared repo truth surfaces the recovery doc is expected to reference.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_project_state_surface.ps1
```

## validate_session_log_surface.ps1

Validates `docs/SESSION_LOG.md` as a repo recovery surface.

Checks include:
- dated section heading presence
- valid `yyyy-MM-dd` heading format
- no future-dated headings
- at least one bullet line per dated section
- valid created-branch entry format

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_session_log_surface.ps1
```

## validate_recovery_surface_manifest.ps1

Validates `config/recovery_surface_manifest.json` as the declared truth source for recovery-surface references.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_recovery_surface_manifest.ps1
```

## Recovery-surface truth source note

`config/recovery_surface_manifest.json` is the declared truth source for Codex surface references and project-state recovery references.

`scripts/validate_codex_surfaces.ps1` and `scripts/validate_project_state_surface.ps1` now consume that manifest instead of hardcoding the same recovery-surface lists separately.

## validate_untracked_repo_files.ps1

Validates that the working tree has no untracked files before proof and commit, while relying on git ignore rules to exclude known temp artifacts.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_untracked_repo_files.ps1
```

## Untracked-file guard note

When a branch creates real new repo files, stage them early and run `scripts/validate_untracked_repo_files.ps1` before final proof and commit.

## validate_scripts_readme_surface.ps1

Validates `scripts/README.md` against the declared recovery-surface truth source at `config/recovery_surface_manifest.json`.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_scripts_readme_surface.ps1
```

## Operator-surface gate integration note

`config/phase2_gate_surface_manifest.json` is the declared truth source for operator-surface gate integration.

Operator-facing recovery validators now integrate through that manifest instead of adding one separate gate-integration note per surface.


## validate_root_doc_surfaces.ps1

Validates `README.md` and `SECURITY.md` against the declared recovery-surface truth source at `config/recovery_surface_manifest.json`.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_root_doc_surfaces.ps1
```

## Root-doc gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_root_doc_surfaces.ps1`, so the standard Phase 2 gate validates `README.md` and `SECURITY.md` before downstream runtime checks.

## validate_authoritative_status_surfaces.ps1

Validates the authoritative status surfaces declared in `README.md` against the recovery-surface truth source at `config/recovery_surface_manifest.json`.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_authoritative_status_surfaces.ps1
```


## validate_phase2_postgres_bootstrap_idempotence.ps1

Validates repeated Phase 2 PostgreSQL bootstrap and schema-bootstrap runs against the local state layer.

Checks include:
- first database bootstrap run passes
- second database bootstrap run settles to `already_exists`
- first schema bootstrap run passes
- second schema bootstrap run passes
- schema drift validation still passes after repeated bootstrap

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_postgres_bootstrap_idempotence.ps1
```

## PostgreSQL state gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_phase2_postgres_bootstrap_idempotence.ps1`, so the standard Phase 2 gate proves repeated local PostgreSQL bootstrap, repeated schema bootstrap, and post-repeat schema-drift validation before downstream runtime checks.


## validate_provider_readiness_invariants.ps1

Validates provider warmup and readiness invariants against a running local Eidon Orchestrator.

Checks include:
- baseline health surface is reachable and state stores are healthy
- first warm call returns `status=warmed` and `provider.ready=true`
- health after warm reports `provider.status=ok` and `provider.ready=true`
- second warm call stays clean and does not regress ready truth
- warm and health payloads agree on provider ready truth after repeated warmup

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_provider_readiness_invariants.ps1
```

## Provider readiness gate integration note

`config/phase2_gate_surface_manifest.json` now separates pre-start `validation_steps` from post-start `post_start_runtime_steps`.

`scripts/validate_provider_readiness_invariants.ps1` is declared in `post_start_runtime_steps` because it requires a live Orchestrator and validates warmup and health agreement after startup.


## validate_orchestration_provenance_invariants.ps1

Validates a real orchestration call against the persisted artifact and lineage retrieval surfaces.

Checks include:
- provider warmup succeeds before orchestration proof
- one real `POST /orchestrate` call returns persisted artifact and lineage identifiers
- `GET /artifacts/{artifact_id}` and `GET /lineage/{artifact_id}` both return the persisted records
- artifact and lineage records agree on provider provenance fields
- artifact and lineage records agree on governance provenance fields
- manifest-backed default governance truth is persisted on the normal success path

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_orchestration_provenance_invariants.ps1
```

## Orchestration provenance gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_orchestration_provenance_invariants.ps1` under `post_start_runtime_steps`.

That means the standard Phase 2 gate proves one real orchestration call persists matching provider and governance provenance across artifact and lineage retrieval surfaces after startup, warmup, and health.


## validate_provider_failure_provenance_invariants.ps1

Validates a forced provider failure path against persisted artifact and lineage retrieval surfaces.

Checks include:
- launches a temporary failure-mode Orchestrator on an alternate local port
- forces a missing-model provider failure path
- verifies `POST /provider/warm` returns `warm_failed` with provider error details
- verifies one real `POST /orchestrate` call returns `provider_failed`
- verifies `GET /artifacts/{artifact_id}` and `GET /lineage/{artifact_id}` return matching persisted failure records
- verifies artifact and lineage records agree on provider failure provenance fields
- verifies fallback governance truth is persisted on provider failure

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_provider_failure_provenance_invariants.ps1
```

## Provider failure provenance gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_provider_failure_provenance_invariants.ps1` under `post_start_runtime_steps`.

That means the standard Phase 2 gate proves a forced provider failure path persists matching failure provenance across artifact and lineage retrieval surfaces after startup, warmup, and baseline runtime checks.


## validate_governance_rule_provenance_invariants.ps1

Validates a real manifest-triggered governance short-circuit path against persisted artifact and lineage retrieval surfaces.

Checks include:
- baseline health surface is reachable
- one real `POST /orchestrate` call triggers a manifest-backed governance rule
- `GET /artifacts/{artifact_id}` and `GET /lineage/{artifact_id}` both return the persisted records
- artifact and lineage records agree on `governance_outcome`, `governance_reason`, `governance_rule_id`, and `governance_manifest_version`
- artifact and lineage records agree on the governance short-circuit provider posture
- the expected manifest rule response text is persisted on the short-circuit path

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_governance_rule_provenance_invariants.ps1
```

## Governance rule provenance gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_governance_rule_provenance_invariants.ps1` under `post_start_runtime_steps`.

That means the standard Phase 2 gate proves a real manifest-triggered governance short-circuit path persists matching governance provenance and short-circuit provider posture across artifact and lineage retrieval surfaces after startup, warmup, and baseline runtime checks.


## validate_routing_fallback_provenance_invariants.ps1

Validates a route-eligible orchestration request that succeeds through control fallback after candidate-model failure.

Checks include:
- launches a temporary routing-enabled Orchestrator on an alternate local port
- keeps the control model usable while forcing a missing candidate model
- verifies the candidate model is reported unavailable in routing surfaces
- sends one route-eligible `POST /orchestrate` request
- verifies the request succeeds through control fallback
- verifies `GET /artifacts/{artifact_id}` and `GET /lineage/{artifact_id}` return matching persisted routing provenance
- verifies `provider_route_mode` is `fallback`
- verifies `provider_route_reason` is `control_fallback_after_candidate_failure`
- verifies the persisted selected model is the control model after fallback

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_routing_fallback_provenance_invariants.ps1
```

## Routing fallback provenance gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_routing_fallback_provenance_invariants.ps1` under `post_start_runtime_steps`.

That means the standard Phase 2 gate proves a route-eligible request can succeed through control fallback after candidate-model failure and persist matching routing provenance across artifact and lineage retrieval surfaces after startup, warmup, and baseline runtime checks.


## validate_routing_candidate_success_provenance_invariants.ps1

Validates a route-eligible orchestration request that succeeds through the candidate model on the routing pilot.

Checks include:
- launches a temporary routing-enabled Orchestrator on an alternate local port
- keeps both control and candidate models usable
- verifies the candidate model is reported healthy in routing surfaces
- sends one route-eligible `POST /orchestrate` request
- verifies the request succeeds through the candidate route
- verifies `GET /artifacts/{artifact_id}` and `GET /lineage/{artifact_id}` return matching persisted routing provenance
- verifies `provider_route_mode` is `candidate`
- verifies `provider_route_reason` is `candidate_domain_route`
- verifies the persisted selected model is the candidate model

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_routing_candidate_success_provenance_invariants.ps1
```

## Routing candidate success provenance gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_routing_candidate_success_provenance_invariants.ps1` under `post_start_runtime_steps`.

That means the standard Phase 2 gate proves a route-eligible request can succeed through the candidate model and persist matching routing provenance across artifact and lineage retrieval surfaces after startup, warmup, and baseline runtime checks.


## validate_routing_control_nonrouteable_provenance_invariants.ps1

Validates a non-routeable orchestration request that stays on the control model while routing is enabled.

Checks include:
- launches a temporary routing-enabled Orchestrator on an alternate local port
- keeps both control and candidate models usable
- verifies the candidate model is reported healthy in routing surfaces
- sends one explicitly non-routeable `POST /orchestrate` request
- verifies the request succeeds on the control model
- verifies `GET /artifacts/{artifact_id}` and `GET /lineage/{artifact_id}` return matching persisted routing provenance
- verifies `provider_route_mode` is `control`
- verifies `provider_route_reason` is `control_non_routeable`
- verifies the persisted selected model is the control model

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_routing_control_nonrouteable_provenance_invariants.ps1
```

## Routing control nonrouteable provenance gate integration note

`config/phase2_gate_surface_manifest.json` now includes `scripts/validate_routing_control_nonrouteable_provenance_invariants.ps1` under `post_start_runtime_steps`.

That means the standard Phase 2 gate proves an explicitly non-routeable request stays on the control model and persists matching routing provenance across artifact and lineage retrieval surfaces after startup, warmup, and baseline runtime checks.

