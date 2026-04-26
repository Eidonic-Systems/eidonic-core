# Codex Context Packet

This file tells Codex what to read before doing repo work.

It is not an authoritative truth source.
It points Codex to the authoritative truth sources already carried by the repo.

If this file conflicts with a manifest, validator, runtime code, or proved command path, the repo truth source wins.

## Role of this file

This packet is for Codex task execution.

It is not the human new-chat recovery flow.
Human new-chat recovery is defined in `docs/CODEX_WORKFLOW.md` under `Recovery rule for new chats`.

Use this packet when Codex is being asked to inspect, edit, audit, review, or diagnose repo surfaces.

## Codex task execution read order

Before any non-trivial Codex task, read:

1. `AGENTS.md`
2. `docs/CODEX_CONTEXT_PACKET.md`
3. `docs/PROJECT_STATE_AT_A_GLANCE.md`
4. latest relevant entries in `docs/SESSION_LOG.md`
5. `docs/CODEX_WORKFLOW.md`
6. `docs/CODEX_TASK_TEMPLATE.md`
7. `docs/CODEX_REPETITIVE_WORK_PACK.md`
8. task-specific manifest, validator, script, service README, or doc

## Current truth sources

Service topology:
- `config/service_topology_manifest.json`

Gate shape:
- `config/phase2_gate_surface_manifest.json`

Recovery surfaces:
- `config/recovery_surface_manifest.json`

Automation-helper surface:
- `config/automation_helper_surface_manifest.json`

Governance rules:
- `config/governance_rules_manifest.json`

Python dependency truth:
- `config/phase2_python_dependency_truth.json`

## Current gate shape

Gate entry:
- `scripts/run_phase2_gate.ps1`

Captured gate entry:
- `scripts/run_phase2_gate_with_capture.ps1`

Declared gate phases:
- `validation_steps`
- `startup_authority_steps`
- `post_start_runtime_steps`

Gate rule:
- static validators belong in `validation_steps`
- startup-authority proof belongs in `startup_authority_steps`
- live endpoint proofs belong in `post_start_runtime_steps`

## Startup authority

Single startup authority:
- `scripts/start_phase_2_stack.ps1`

Rules:
- do not start the stack twice
- do not manually pre-start the stack before a gate wrapper unless `-SkipStackStart` is intentionally used
- `scripts/run_phase2_gate.ps1` owns startup for full gate runs unless `-SkipStackStart` is used
- `scripts/run_declared_runtime_proof.ps1` is phase-aware and owns startup only for manual `post_start_runtime_steps` runs unless `-SkipStackStart` is used

## Automation-helper posture

Truth source:
- `config/automation_helper_surface_manifest.json`

Manifest validator:
- `scripts/validate_automation_helper_surface_manifest.ps1`

Broader helper validator:
- `scripts/validate_automation_helpers.ps1`

Rules:
- helper coverage comes from the manifest, not hardcoded lists
- standalone helper validation prechecks the manifest validator first
- full gate runs skip duplicate helper-manifest proof only when upstream gate order already proved it

## Recovery-surface posture

Truth source:
- `config/recovery_surface_manifest.json`

Key validators:
- `scripts/validate_recovery_surface_manifest.ps1`
- `scripts/validate_codex_surfaces.ps1`
- `scripts/validate_project_state_surface.ps1`
- `scripts/validate_session_log_surface.ps1`
- `scripts/validate_scripts_readme_surface.ps1`
- `scripts/validate_root_doc_surfaces.ps1`
- `scripts/validate_authoritative_status_surfaces.ps1`

Rules:
- recovery docs should reference declared truth sources
- project-state should stay compact and current
- session log records branch history, not architecture essays
- public docs must not overclaim runtime posture

## Truth classification

Classify claims before editing docs.

Live repo surface:
- present in current repo files, manifests, scripts, schemas, or docs

Local operator-proved surface:
- proved through local startup, validator, or gate path

Declared validation surface:
- declared by a manifest or validator, but not necessarily broad runtime generalization

Target posture:
- intended design direction, not yet broad/live/proved

If unsure, use weaker wording.

## Codex allowed work

Codex is good for:
- public doc truth reconciliation
- manifest reference propagation
- validator failure diagnosis
- audit readout triage
- scripts README synchronization
- project-state synchronization
- small bounded doc fixes
- PR review for scope creep, missing proof, and truth drift

## Codex forbidden work without explicit human approval

Do not autonomously:
- change governance policy meaning
- change Mirror Laws or Guardian doctrine
- change GitHub workflow trust boundaries
- change runtime persistence semantics
- change model routing policy
- add broad dependencies
- rewrite service architecture
- merge pull requests
- treat handoff files as authoritative

## Required task sequence

For Codex edit tasks:

1. inspect
2. report findings
3. ask approval before editing
4. edit only approved files
5. run or request required proof
6. report changed files, proof result, risks, and human review needs

## Standard Codex final report

Codex should end with:

- Summary
- Changed files
- Proof run
- Proof result
- Risks
- Human review needed

## Current next operating direction

Current near-term direction:
- use Codex for bounded repetitive repo-maintenance work
- keep human approval over architecture, governance, runtime semantics, and merges
- use Codex PR review once GitHub Codex review is connected
- preserve repo-carried truth across chats by using this packet as the default starting index for non-trivial Codex tasks, followed by the linked truth sources

## Final rule

Codex is a worker, reviewer, and drift detector.

It is not the source of repo truth.



