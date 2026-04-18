# Phase 2 Governance Rule Fixtures Surface

This document records the first deterministic fixture surface for the current governance manifest pilot.

## Purpose
Add explicit positive and negative fixtures for every current governance rule before widening the pilot.

## What changed
- added `tests/fixtures/governance_rule_fixtures.json`
- added `scripts/test_governance_rule_fixtures.ps1`

## Covered rules
- `refuse_impersonation_request`
- `hold_material_ambiguity_command`
- `reshape_scope_drift_request`
- `handoff_human_review_event`

## What the fixture surface proves
- each current rule has a deterministic positive case
- each current rule has a deterministic negative case
- current manifest behavior matches the documented pilot shape

## Why this matters
- the audit explicitly called for deterministic positive and negative fixtures for every rule
- fixture-backed rule coverage is stronger than trusting prose descriptions
- this keeps the governance pilot narrow, explicit, and reviewable

## Current truth
This branch adds fixture-backed rule coverage only.

It does not:
- add new governance outcomes
- widen pilot semantics
- change routing behavior
- change model behavior
