# Phase 2 Local Provider Eval Drift Guards

This document records the hardening of the local provider eval surface against identity, formatting, and encoding drift.

## Purpose
Catch response drift that matters operationally before any future Gemma-family routing policy or runtime routing is introduced.

## What changed
- updated `evals/local_provider_eval_cases.json`
- updated `scripts/run_local_provider_eval.ps1`
- plain-text expectations are now explicit in the eval cases
- the eval runner now fails on:
  - identity drift
  - encoding drift
  - formatting drift
  - provider failure
  - missing required substrings
  - forbidden substrings

## Drift classes
- identity drift:
  - response leaks the wrong model identity
- encoding drift:
  - response contains garbled punctuation artifacts
- formatting drift:
  - fenced JSON or wrapper-style output appears where plain text is expected

## Why this matters
- a narrow pass/fail baseline is not enough once multiple Gemma-family candidates are being compared
- routing policy should not be discussed seriously until drift is visible in the eval surface
- this hardens measurement without widening runtime complexity

## Current truth
The local provider eval surface now checks for more than regressions. It also checks whether the output stays readable, plain, and identity-consistent.
