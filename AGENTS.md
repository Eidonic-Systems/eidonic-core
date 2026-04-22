# AGENTS.md

This file defines how coding agents should operate inside `eidonic-core`.

## Core rule

Do not improvise repo truth.

Read the declared truth surfaces first, then make the smallest bounded change that satisfies the task.

## Current repo posture

- Phase 2 repo with manifest-backed topology, governance, dependency, and gate surfaces
- Local-first operating model
- Windows PowerShell is the primary operator path
- Self-hosted Windows runner used for the Phase 2 GitHub Actions gate

## Priority truth surfaces

Read these before making structural changes:
- `README.md`
- `SECURITY.md`
- `docs/PROJECT_STATE_AT_A_GLANCE.md`
- `docs/SESSION_LOG.md`
- `config/service_topology_manifest.json`
- `config/governance_rules_manifest.json`
- `config/phase2_python_dependency_truth.json`
- `scripts/run_phase2_gate.ps1`
- `scripts/start_phase_2_stack.ps1`
- `scripts/validate_*.ps1`

## Branch discipline

- one bounded branch at a time
- no branch spray
- no hidden helper rewrites outside branch scope
- merge on GitHub, then update local first
- do not leave branch work undocumented

## Required docs updates

Every Codex-driven structural branch must update:
- `docs/SESSION_LOG.md`

Update `docs/PROJECT_STATE_AT_A_GLANCE.md` whenever any of these change:
- service topology truth
- gate surfaces
- dependency truth source
- governance posture
- runner trust posture
- Codex operating rules

## Proof rule

Do not claim completion without running the smallest relevant proof.

Preferred proof order:
- targeted validator first
- then broader gate only if the branch touches gate-relevant surfaces

Common proofs:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_service_topology_manifest.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_topology_consistency.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_dependency_pins.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1`

## Do-not rules

- do not invent new truth sources when one already exists
- do not hardcode versions into validators when they belong in a manifest or truth file
- do not merge split dependency PRs one by one when they represent one shared dependency wave
- do not treat self-hosted runner behavior as ephemeral unless the repo explicitly proves it
- do not update docs after the fact; update them inside the branch

## Repo-specific operating expectations

- topology truth lives in `config/service_topology_manifest.json`
- dependency truth lives in `config/phase2_python_dependency_truth.json`
- gate entry point is `scripts/run_phase2_gate.ps1`
- startup entry point is `scripts/start_phase_2_stack.ps1`
- shared package truth for schemas lives in `packages/common-schemas/python/pyproject.toml`

## Done means

A branch is done only when:
- the bounded change is implemented
- the relevant validator or gate passes
- `docs/SESSION_LOG.md` is updated
- `docs/PROJECT_STATE_AT_A_GLANCE.md` is updated if structural truth changed
- the PR description states what changed, why, and what proof passed


## Codex validation proof

- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_codex_surfaces.ps1`


## Recovery-surface truth source

- `config/recovery_surface_manifest.json`

## Recovery-surface proof

- `scripts/validate_recovery_surface_manifest.ps1`
