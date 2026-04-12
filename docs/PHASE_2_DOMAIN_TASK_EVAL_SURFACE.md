# Phase 2 Domain Task Eval Surface

This document records the first domain-specific eval surface for Eidonic Core.

## Purpose
Move evaluation beyond toy prompts and toward the kinds of orchestration responses the real system actually needs.

## What changed
- added `evals/domain_task_eval_cases.json`
- added `scripts/run_domain_task_eval.ps1`
- updated `.gitignore` to ignore generated `evals/domain_task_eval_results.json`

## Current domain task classes
- next-step guidance after provider warmup
- artifact-lineage follow-up
- provider-failure guidance
- threshold-hold guidance
- postgres state-spine preflight guidance

## Why this matters
- generic eval cases were enough to harden the pipeline
- they are not enough to make serious Gemma-family decisions for the real system
- future model and routing decisions should be based on work the system actually cares about

## Current truth
This branch adds domain-specific evaluation only. It does not change runtime behavior, routing, or the default model.
