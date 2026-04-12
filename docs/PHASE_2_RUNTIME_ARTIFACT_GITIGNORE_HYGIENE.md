# Phase 2 Runtime Artifact Gitignore Hygiene

This document records the cleanup of generated local runtime artifacts from normal Git tracking.

## Purpose
Keep generated local eval outputs out of source control while preserving tracked eval inputs and pinned baselines.

## What changed
- updated `.gitignore`
- ignored `evals/local_provider_eval_results.json`
- ignored `evals/candidates/`

## What remains tracked
- `evals/local_provider_eval_cases.json`
- `evals/baselines/`

## Why this matters
- generated local outputs should not keep polluting `git status`
- measurement workflow should not create fake branch confusion
- the repo should distinguish between source artifacts and runtime artifacts
