# Phase 2 Gemma Candidate Runtime Profile Surface

This document records the first narrow runtime profiling surface for Gemma-family candidate comparison.

## Purpose
Measure whether a smaller Gemma-family candidate provides a real runtime advantage on the local machine while still passing the current eval surface.

## What changed
- added `scripts/profile_gemma_candidate_runtime.ps1`
- updated `.gitignore` to ignore generated runtime profile outputs under `evals/profiles/`

## What the profile measures
- isolated provider warmup time
- isolated end-to-end eval run time
- total profile time
- passing or failing eval status for each model

## Current comparison target
- control model: `gemma3n:e4b`
- candidate model: `gemma3n:e2b`

## Why this matters
- candidate promotion needs a real advantage, not just a no-regression result
- runtime profile is how the build proves or kills the “lightweight route candidate” claim
- this keeps measurement local, narrow, and actionable

## Current truth
This branch adds runtime evidence gathering. It does not add routing, change the default model, or alter runtime behavior.
