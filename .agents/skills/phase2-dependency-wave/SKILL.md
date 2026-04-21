---
name: phase2-dependency-wave
description: Use when Eidonic Core receives multiple dependency PRs that represent one shared dependency wave across services, shared packages, validators, and docs.
---

1. Do not merge split bot PRs one by one if they affect one shared dependency truth.
2. Create one bounded manual absorption branch.
3. Update all affected service requirement files and the shared package together.
4. Update `config/phase2_python_dependency_truth.json` if the approved version changes.
5. Update validator surfaces only if they consume the truth source and need logic changes, not because version truth is hardcoded again.
6. Run dependency pin validation first.
7. Run the Phase 2 gate after dependency validation passes.
8. Update `docs/SESSION_LOG.md` and mention why the wave was absorbed as one branch.
9. Close superseded bot PRs after the coordinated branch merges.

Repo-specific dependency truth:
- Truth file: `config/phase2_python_dependency_truth.json`
- Shared package: `packages/common-schemas/python/pyproject.toml`
- Gate proof: `powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1`

Do not:
- retype dependency truth independently across validators
- absorb shared-package version changes without keeping all four Phase 2 services aligned
- claim completion before `validate_phase2_dependency_pins.ps1` passes
