# Phase 2 Domain Task Candidate Comparison Surface

This document records the first candidate-comparison workflow for the domain-task eval surface.

## Purpose
Judge a model candidate against the system's actual work instead of relying only on the generic provider eval surface.

## What changed
- added `scripts/run_domain_task_candidate_eval.ps1`

## What the workflow does
- starts an isolated Orchestrator with a model override
- warms the candidate provider
- verifies the warmed model matches the requested candidate
- runs `scripts/run_domain_task_eval.ps1`
- compares the candidate results against `evals/baselines/domain_task_eval_baseline.json`
- writes candidate results under `evals/candidates`

## Why this matters
- generic comparison is no longer enough
- future Gemma decisions should be judged against domain-relevant work
- this keeps the live default model unchanged while still allowing disciplined candidate evaluation

## Current truth
This branch adds domain-task candidate comparison only. It does not change runtime behavior, routing, or the default model.
