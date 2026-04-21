# Phase 2 Dependency Reproducibility Surface

This document records the first bounded dependency reproducibility pass for the Phase 2 Python services.

## Purpose
Reduce rebuild drift by pinning still-floating direct Python dependencies without pretending the repo already has full lockfile discipline.

## What changed
- added `scripts/pin_phase2_python_dependencies.ps1`
- updated service `requirements.txt` files where direct dependencies were still floating

## What the script does
- inspects the four Phase 2 service `requirements.txt` files
- uses each service `.venv` as the source of currently installed package versions
- rewrites still-floating direct dependencies to exact `==` pins where possible
- leaves editable paths, URLs, comments, and already pinned lines alone
- reports unresolved entries instead of pretending everything is locked

## Current lock posture
Current truth after this branch:
- direct service dependencies should be more tightly pinned
- editable local package references remain editable
- transitive dependency resolution is still not fully locked
- this is a bounded reproducibility improvement, not a final lockfile strategy

## Why this matters
- the audit correctly identified dependency realization drift as a medium-severity reproducibility weakness
- pinning floating direct dependencies is the first sane step before any heavier lock strategy
- this keeps the change narrow, reviewable, and reversible

## Single dependency truth source update

The current Phase 2 Python dependency posture now has one declared repo truth source:
- `config/phase2_python_dependency_truth.json`

That file defines:
- the editable shared package line expected in each service `requirements.txt`
- the required exact direct pins for each Phase 2 service
- the required shared package dependency pins for `packages/common-schemas/python/pyproject.toml`

The dependency validator now reads this file instead of hardcoding version truth directly inside the script.

This change exists to reduce drift between:
- service requirement files
- shared package dependency declarations
- validator expectations
- future dependency absorption work

Operational rule:
Phase 2 Python dependency version truth should be declared once and consumed by validation surfaces, not retyped independently across multiple repo control surfaces.

## Dependency truth sync surface update

The current Phase 2 Python dependency truth source now has both a validation surface and a write surface.

Declared truth source:
- `config/phase2_python_dependency_truth.json`

Validation surface:
- `scripts/validate_phase2_dependency_pins.ps1`

Sync surface:
- `scripts/sync_phase2_dependency_truth.ps1`

Operational rule:
- update the truth file first
- run the sync surface to rewrite dependent files
- run the validation surface to confirm alignment

This reduces manual edit churn across service requirements, the shared package dependency block, and future dependency-wave absorption work.
