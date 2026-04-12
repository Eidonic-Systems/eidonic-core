# Phase 2 Local Provider Candidate Comparison

This document records the first narrow candidate-comparison workflow for the local provider path.

## Purpose
Measure one alternate local model candidate against the pinned baseline without changing the live default provider model.

## What changed
- added `scripts/run_local_provider_candidate_eval.ps1`
- candidate comparison now:
  - starts an isolated Orchestrator with a provider-model override
  - warms the candidate provider
  - runs the local provider eval surface
  - writes candidate results to `evals/candidates`
  - compares candidate results to the pinned baseline
  - shuts the isolated candidate process down

## Why this matters
- comparison should happen before default-model changes
- future model decisions should be based on evidence, not excitement
- this keeps candidate testing local, narrow, and reversible

## Current truth
The live default provider model remains unchanged. Candidate comparison happens through an isolated override path only.
