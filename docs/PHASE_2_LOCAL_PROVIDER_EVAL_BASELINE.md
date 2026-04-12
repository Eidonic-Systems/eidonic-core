# Phase 2 Local Provider Eval Baseline

This document records the first pinned baseline for the local provider eval surface.

## Purpose
Freeze the current passing local provider behavior so future changes can be compared against a known-good baseline.

## What changed
- added `evals/baselines/local_provider_eval_baseline.json`
- added `scripts/compare_local_provider_eval_to_baseline.ps1`

## Why this matters
- an eval surface without a baseline still leaves too much to memory
- future prompt, model, and provider changes need a comparison point
- this keeps comparison local, narrow, and explicit

## Current truth
The current passing local provider eval results are now pinned as the first baseline for future comparison.
