# Codex Repetitive Work Pack

This document defines the repetitive work Codex may handle with bounded supervision.

Codex should be used to reduce manual churn.
It should not be used to make architecture decisions or invent current repo truth.

## Work class 1: public doc truth reconciliation

Purpose:
- align public-facing docs with current repo proof surfaces

Usually allowed:
- `README.md`
- `docs/PHASE_2_STATUS.md`
- `docs/PROJECT_STATE_AT_A_GLANCE.md`
- `docs/CODEX_WORKFLOW.md`
- service README files
- `docs/SESSION_LOG.md`

Usually forbidden:
- runtime service code
- gate runner scripts
- startup scripts
- manifests, unless the task explicitly names a manifest edit

Required proof:
- `scripts/validate_recovery_surface_manifest.ps1`
- `scripts/validate_codex_surfaces.ps1`
- `scripts/validate_project_state_surface.ps1`
- `scripts/validate_root_doc_surfaces.ps1`
- `scripts/validate_authoritative_status_surfaces.ps1`
- `scripts/validate_session_log_surface.ps1`

## Work class 2: manifest reference propagation

Purpose:
- when a manifest gains a new declared surface, propagate references into the docs and validators that are supposed to know about it

Required proof:
- the manifest-specific validator
- downstream doc validators
- session-log validator

## Work class 3: scripts README synchronization

Purpose:
- keep `scripts/README.md` aligned when scripts are added, renamed, or behavior changes

Required proof:
- `scripts/validate_scripts_readme_surface.ps1`
- `scripts/validate_session_log_surface.ps1`

## Work class 4: project-state synchronization

Purpose:
- keep `docs/PROJECT_STATE_AT_A_GLANCE.md` compact, current, and aligned with declared truth sources

Required proof:
- `scripts/validate_project_state_surface.ps1`
- `scripts/validate_session_log_surface.ps1`

## Work class 5: audit readout triage

Purpose:
- classify audit findings as confirmed, stale, false positive, needs runtime proof, needs repo reconciliation, or needs implementation branch

Required output:
- Finding
- Classification
- Evidence
- Recommended branch
- Allowed files
- Required proof
- Risk if ignored

## Work class 6: validator failure diagnosis

Purpose:
- diagnose validator failures without blindly editing files

Required method:
1. Read the validator script.
2. Read the manifest or doc it consumes.
3. Reproduce the exact failed pattern or check.
4. Identify whether failure is missing doc text, bad regex, stale manifest expectation, real repo drift, or wrong proof command.
5. Propose the smallest fix.

Forbidden Codex work without explicit human approval:
- changing governance policy meaning
- changing Mirror Laws or Guardian doctrine
- changing branch protection assumptions
- changing GitHub workflow trust boundaries
- changing runtime persistence semantics
- changing model routing policy
- adding broad dependencies
- rewriting service architecture
- merging pull requests
