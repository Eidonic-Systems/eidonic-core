# Phase 2 Governance Eval Baseline Refresh

This document records the refresh of the governance eval baseline after the runtime governance pilot reached full six-outcome coverage.

## Purpose
Bring the pinned governance baseline back into alignment with the current manifest-backed runtime behavior.

## What changed
- refreshed `evals/baselines/governance_eval_baseline.json`

## Why this matters
- the previous baseline still passed comparison, but it no longer reflected the cleanest current truth
- `reshape` and `handoff` are now part of live narrow runtime governance coverage
- the pinned governance reference should match current reality, not older wording

## Current truth
The governance eval baseline now reflects the current six-outcome governance surface:
- `allow`
- `reshape`
- `hold`
- `handoff`
- `refuse`
- `fallback`

This is a baseline refresh only. It does not introduce new enforcement logic.
