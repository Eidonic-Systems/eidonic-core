# Phase 2 Shared Schemas Pydantic Alignment

This document records the branch that aligns the shared editable schema package with the Phase 2 service `pydantic` upgrade.

## Purpose
Remove the actual dependency anchor blocking the isolated `pydantic` compatibility batch.

## What changed
- updated the shared schemas package dependency pin from `pydantic==2.9.2` to `pydantic==2.13.2`
- updated all four Phase 2 service requirements to `pydantic==2.13.2`

## Why this matters
The failed isolated `pydantic` batch exposed the real blocker:
the editable local package `eidonic-schemas 0.1.0` still depended on `pydantic==2.9.2`.

Until the shared package moved, the service environments could not resolve `pydantic==2.13.2` cleanly.

## Current truth
This branch aligns the shared schemas package and the four services on one `pydantic` version.

It does not:
- widen upgrades beyond `pydantic`
- change governance behavior
- change routing behavior
- change CI behavior
