# Codex Task Template

Use this template for bounded Codex work.

Codex is a worker, not the architect.
It may inspect, edit, test, summarize, and propose changes inside the declared scope.
It may not invent repo truth, expand scope, or treat handoff files as authoritative.

## Task title

`<short imperative task title>`

## Goal

State the concrete outcome.

## Allowed files

List exact files or directories Codex may edit.

## Forbidden files

Default forbidden unless explicitly allowed:
- `.github/workflows/`
- `config/phase2_gate_surface_manifest.json`
- `config/recovery_surface_manifest.json`
- `config/automation_helper_surface_manifest.json`
- `config/governance_rules_manifest.json`
- `services/**`
- `packages/**`
- `scripts/run_phase2_gate.ps1`
- `scripts/start_phase_2_stack.ps1`

## Truth source

Name the source Codex must read before editing.

Examples:
- `config/recovery_surface_manifest.json`
- `config/phase2_gate_surface_manifest.json`
- `config/automation_helper_surface_manifest.json`
- `docs/PROJECT_STATE_AT_A_GLANCE.md`
- `scripts/README.md`

## Required proof

List exact commands.

## Acceptance criteria

- Scope stayed inside allowed files.
- Forbidden files were not edited.
- Required proof passed.
- Docs distinguish live repo surfaces, local operator-proved surfaces, declared validation surfaces, and target posture.
- Session log entry was added if repo files changed.

## Required final report

Codex must report:
- Summary
- Changed files
- Proof run
- Proof result
- Risks
- Human review needed

## Stop conditions

Codex must stop and ask for review if:
- required truth source is missing
- proof command is missing
- proof fails twice
- task requires editing forbidden files
- runtime status is ambiguous
- scope expands beyond the task
