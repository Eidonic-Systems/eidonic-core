# Project State at a Glance

## Current phase

Phase 2 build solidification, trust-surface hardening, and Codex operating-surface setup.

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

Current gate validation surfaces include:
- dependency pin validation
- service topology manifest validation
- topology consistency validation
- PostgreSQL bootstrap and schema checks
- health verification
- governance gate

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

- `scripts/validate_automation_helpers.ps1`

## Current gate posture update

Current gate validation surfaces also include:
- automation helper validation

## Current workflow gate capture posture

- `.github/workflows/phase2-gate.yml` runs `scripts/run_phase2_gate_with_capture.ps1`
- the workflow uploads captured Phase 2 gate output as a workflow artifact

## Current temp-file hygiene surface

- `.gitignore` ignores local proof artifact files
- `scripts/finish_merged_branch.ps1` pre-cleans known temp output files before dirty-tree refusal

## Current cleanup idempotence posture

- `scripts/finish_merged_branch.ps1` treats an already-absent local branch as an idempotent cleanup outcome

## Current temp-hygiene validation posture

- `scripts/validate_automation_helpers.ps1` proves ignored local proof artifacts do not change git status
- `scripts/validate_automation_helpers.ps1` proves merged-branch cleanup still includes temp-file pre-clean behavior
