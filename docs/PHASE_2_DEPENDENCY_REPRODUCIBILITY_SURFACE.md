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
