# Phase 2 Governance Rule Provenance Surface

This document records the persistence of manifest rule identity for the narrow governance enforcement pilot.

## Purpose
Persist not only governance outcome and reason, but also which rule fired and which manifest version produced that outcome.

## What changed
- updated the governance manifest to include a default success rule id
- added governance rule id and governance manifest version to artifact provenance
- added governance rule id and governance manifest version to lineage provenance
- added `tests/integration/test_governance_rule_provenance_surface.ps1`

## Persisted fields
Artifact:
- `governance_rule_id`
- `governance_manifest_version`

Lineage:
- `artifact_governance_rule_id`
- `artifact_governance_manifest_version`

## Why this matters
- visible rules are not enough without persisted rule identity
- manifest-backed enforcement should be auditable end to end
- this reduces reconstruction work when reviewing governance behavior later

## Current truth
This branch adds rule identity provenance only. It does not widen enforcement scope.
