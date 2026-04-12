# Phase 2 Local Provider Eval Surface

This document records the first narrow local evaluation surface for the current provider path.

## Purpose
Create a repeatable local baseline for the current Orchestrator provider before adding more models, routing, or tuning work.

## What changed
- added `evals/local_provider_eval_cases.json`
- added `scripts/run_local_provider_eval.ps1`
- added a small deterministic rubric:
  - response must not be a provider failure
  - response must meet a minimum length
  - response must include required substrings
  - response must avoid forbidden substrings

## Why this matters
- future provider comparisons need a baseline
- prompt or model changes should not be judged by vibes
- this keeps evaluation narrow, local, and repeatable

## Current truth
The current local provider eval surface is small on purpose. It is not a benchmark suite. It is a baseline check for the current live provider path.
