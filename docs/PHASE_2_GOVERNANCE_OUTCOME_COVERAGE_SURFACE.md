# Phase 2 Governance Outcome Coverage Surface

This document records the extension of the narrow manifest-backed governance pilot to cover the remaining named runtime outcomes from the governance eval surface.

## Purpose
Close the mismatch between governance outcomes the repo can evaluate and governance outcomes the runtime pilot can actually enforce.

## What changed
- updated `config/governance_rules_manifest.json`
- updated `services/eidon-orchestrator/app/main.py`
- added `tests/integration/test_governance_outcome_coverage_surface.ps1`

## Added runtime outcome coverage
- `reshape` through a narrow scope-drift rule
- `handoff` through a narrow human-review event rule

## Why this matters
- the governance eval surface already named `reshape` and `handoff`
- runtime governance previously enforced only `allow`, `fallback`, `refuse`, and `hold`
- this branch closes that runtime coverage gap without widening scope beyond two explicit additions

## Current truth
The narrow manifest-backed governance pilot now covers:
- `allow`
- `fallback`
- `refuse`
- `hold`
- `reshape`
- `handoff`

This is still not a full Guardian engine. It is a narrow, auditable coverage expansion.
