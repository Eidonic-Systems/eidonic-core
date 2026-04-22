# Codex Workflow

This document defines the repo-standard workflow for Codex-assisted changes.

## Purpose

Make Codex useful without turning the repo into agent-chaos.

## Current operating position

Codex should be used for bounded implementation, validation, documentation, and review-surface work inside the repo.

Codex should not be used as a substitute for repo truth, architectural judgment, or uncontrolled multi-branch experimentation.

## Repo Codex surfaces

- project config: `.codex/config.toml`
- repo skills: `.agents/skills/`
- repo instructions: `AGENTS.md`

## Standard branch flow

1. update local `main`
2. create one bounded branch
3. read the relevant truth surfaces first
4. make only the scoped change
5. run the smallest relevant proof
6. update `docs/SESSION_LOG.md`
7. update `docs/PROJECT_STATE_AT_A_GLANCE.md` if structural repo truth changed
8. commit and push
9. open PR with summary, why, scope, and proof
10. merge on GitHub
11. update local `main` and delete the branch

## Required branch artifacts

Every Codex-driven structural branch should leave behind:
- the implementation change
- proof output or a proved command path
- a session log entry
- an updated project-at-a-glance surface when needed

## Good Codex tasks

- validator creation and maintenance
- truth-surface synchronization
- dependency-wave absorption with proof
- docs and governance surface updates
- bounded runtime fixes with a clear proof path

## Bad Codex tasks

- vague refactors with no proof target
- simultaneous unrelated changes across many surfaces
- architectural rewrites without declared truth updates
- speculative automation not tied to current repo pain

## Recovery rule for new chats

At the start of a new chat, read in this order:
- `docs/PROJECT_STATE_AT_A_GLANCE.md`
- latest entries in `docs/SESSION_LOG.md`
- `AGENTS.md`
- then the specific manifest, script, or doc tied to the requested task

## Dependency-wave rule

When multiple bot PRs represent one shared dependency wave:
- do not merge them individually
- absorb them on one bounded manual branch
- keep shared package and service dependency truth aligned
- update the dependency truth source if the approved version changes

## Operator note

The primary local path is Windows PowerShell from `C:\eidonic_core`.

Use one-line commands or closed command blocks where practical to avoid unfinished PowerShell prompts.

## Current branch automation surfaces

The repo now includes bounded PowerShell helpers for recurring local workflow steps:
- `scripts/start_bounded_branch.ps1`
- `scripts/finish_merged_branch.ps1`
- `scripts/run_phase2_gate_with_capture.ps1`
- `scripts/append_session_log_entry.ps1`

These exist to reduce repeated manual branch churn and keep proof and session-log discipline more consistent.

## Automation helper validation rule

When changing any of these surfaces:
- `scripts/start_bounded_branch.ps1`
- `scripts/finish_merged_branch.ps1`
- `scripts/run_phase2_gate_with_capture.ps1`
- `scripts/append_session_log_entry.ps1`
- `scripts/sync_phase2_dependency_truth.ps1`
- `scripts/absorb_phase2_dependency_wave.ps1`

run:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_automation_helpers.ps1`

## Codex surface validation rule

When changing any of these surfaces:
- `AGENTS.md`
- `.codex/config.toml`
- `.agents/skills/`
- `docs/CODEX_WORKFLOW.md`
- `docs/PROJECT_STATE_AT_A_GLANCE.md`

run:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_codex_surfaces.ps1`


## Project-state gate integration rule

`docs/PROJECT_STATE_AT_A_GLANCE.md` now has a dedicated validator and that validator is included in the standard Phase 2 gate through `config/phase2_gate_surface_manifest.json`.

## Session-log gate integration rule

`docs/SESSION_LOG.md` now has a dedicated validator and that validator is included in the standard Phase 2 gate through `config/phase2_gate_surface_manifest.json`.

## Untracked-file guard rule

When a branch creates new repo files, stage them early and run:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_untracked_repo_files.ps1`

Do this before final proof and commit so new repo files do not sit untracked until the end of the branch.

## Untracked-file gate integration rule

`scripts/validate_untracked_repo_files.ps1` is now included in the standard Phase 2 gate through `config/phase2_gate_surface_manifest.json`.

## Recovery-surface validation rule

`config/recovery_surface_manifest.json` is the declared truth source for recovery-surface references.

When changing recovery-surface docs or the recovery-surface manifest, run:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_recovery_surface_manifest.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_codex_surfaces.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_project_state_surface.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_session_log_surface.ps1`


## Scripts-README surface validation rule

When changing `scripts/README.md`, run:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_scripts_readme_surface.ps1`

## Scripts-README gate integration rule

`scripts/validate_scripts_readme_surface.ps1` is now included in the standard Phase 2 gate through `config/phase2_gate_surface_manifest.json`.
