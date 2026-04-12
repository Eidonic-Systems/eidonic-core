# Phase 2 Gemma Candidate Runtime Decision Update

This document records the decision update after local runtime profiling of `gemma3n:e2b` against the current control model.

## Purpose
Tighten the candidate decision using runtime evidence instead of leaving the earlier hold language too optimistic.

## What changed
- updated `docs/decision_records/GEMMA3N_E2B_CANDIDATE_DECISION.md`

## Why this matters
- passing the eval surface is not enough for lightweight promotion
- runtime advantage needs to be measured, not assumed
- the current machine-level evidence matters more than model-size intuition

## Current truth
`gemma3n:e2b` remains a valid Gemma-family candidate, but it does not currently justify lightweight routing or default promotion on this machine because its total runtime profile was slower than `gemma3n:e4b`.
