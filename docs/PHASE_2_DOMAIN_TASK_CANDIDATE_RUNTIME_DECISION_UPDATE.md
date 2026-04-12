# Phase 2 Domain Task Candidate Runtime Decision Update

This document records the decision update after domain-task runtime profiling of `gemma3n:e2b` against the current control model.

## Purpose
Turn the domain-task runtime evidence into an explicit model decision instead of leaving the result as terminal history.

## What changed
- updated `docs/decision_records/GEMMA3N_E2B_CANDIDATE_DECISION.md`
- updated `docs/MODEL_DECISION_INDEX.md`

## Why this matters
- the candidate now has stronger evidence than a vague hold status
- domain-task runtime advantage matters more than size intuition
- the repo should record the split truth clearly:
  - not a default replacement
  - conditionally relevant for narrow future domain-task routing

## Current truth
`gemma3n:e4b` remains the control model.

`gemma3n:e2b` is now recorded as a conditional domain-task routing candidate, not because it won universally, but because it showed real runtime advantage on the domain-task eval surface while still passing that surface cleanly.
