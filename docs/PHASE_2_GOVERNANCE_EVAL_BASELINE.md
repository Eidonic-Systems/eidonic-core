# Phase 2 Governance Eval Baseline

This document records the first pinned baseline for the governance eval surface.

## Purpose
Freeze the current passing governance behavior so future governance changes can be compared against a known reference.

## What changed
- added `evals/baselines/governance_eval_baseline.json`
- added `scripts/compare_governance_eval_to_baseline.ps1`

## Why this matters
- governance behavior should not drift into memory or mood
- future enforcement changes should be judged against a pinned baseline
- this keeps governance comparison local, narrow, and explicit

## Current truth
The current passing governance eval results are now pinned as the first baseline for future comparison.
