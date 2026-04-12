# Phase 2 Governance Eval Surface

This document records the first explicit governance eval surface in Eidonic Core.

## Purpose
Turn the new governance layer into named eval cases instead of leaving outcome classes as policy text only.

## What changed
- added `evals/governance_eval_cases.json`
- added `scripts/run_governance_eval.ps1`
- updated `.gitignore` to ignore generated governance eval results

## Governance outcome classes covered
- `allow`
- `reshape`
- `hold`
- `handoff`
- `refuse`
- `fallback`

## Why this matters
- policy without tests is still just text
- future Guardian work needs a named governance eval surface before runtime enforcement
- this lets the repo test governance-language discipline without pretending Guardian Protocol is already live

## Current truth
This branch adds governance evaluation only. It does not introduce runtime Guardian enforcement.
