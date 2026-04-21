---
name: phase2-branch-flow
description: Use when working on Eidonic Core branch execution, proof, PR prep, merge cleanup, or session-log discipline for one bounded branch.
---

1. Start from updated `main`.
2. Create one bounded branch only.
3. Read the relevant repo truth surfaces before changing files.
4. Make the smallest change that satisfies the branch goal.
5. Run the smallest relevant proof first. Use the full gate only when the branch touches gate-relevant surfaces.
6. Update `docs/SESSION_LOG.md` on every structural branch.
7. Update `docs/PROJECT_STATE_AT_A_GLANCE.md` whenever structural repo truth changes.
8. Prepare PR output with four parts: Summary, What changed, Why, Proof.
9. After merge, switch to `main`, pull fast-forward only, prune, and delete the local branch.

Repo-specific rules:
- Do not invent new truth sources when one already exists.
- Do not hardcode version truth into validators when it belongs in `config/phase2_python_dependency_truth.json`.
- Do not merge split dependency bot PRs one by one when they represent one shared wave.
- Use Windows PowerShell command blocks that are closed and paste-safe.

Common proofs:
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_service_topology_manifest.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_topology_consistency.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_dependency_pins.ps1`
- `powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1`
