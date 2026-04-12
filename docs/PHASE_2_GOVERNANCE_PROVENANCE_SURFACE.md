# Phase 2 Governance Provenance Surface

This document records the first persisted governance outcome surface in Eidonic Core.

## Purpose
Persist governance outcome class and governance reason so governance decisions can be retrieved instead of remaining only implied by policy or eval text.

## What changed
- updated shared schema models to include governance provenance fields
- updated Orchestrator artifact and lineage persistence to store governance outcome and reason
- added `tests/integration/test_governance_provenance_surface.ps1`

## Persisted governance fields
Artifact:
- `governance_outcome`
- `governance_reason`

Lineage:
- `artifact_governance_outcome`
- `artifact_governance_reason`

## Why this matters
- governance outcomes should be auditable
- provenance is the bridge between policy/eval and future enforcement
- this allows the repo to distinguish governance meaning from ordinary provider provenance

## Current truth
This branch adds governance provenance only. It does not introduce runtime Guardian enforcement.
