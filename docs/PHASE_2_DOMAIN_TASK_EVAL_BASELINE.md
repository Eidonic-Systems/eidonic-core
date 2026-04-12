# Phase 2 Domain Task Eval Baseline

This document records the first pinned baseline for the domain-task eval surface.

## Purpose
Freeze the current passing domain-task behavior so future model or routing decisions can be compared against a known reference.

## What changed
- added `evals/baselines/domain_task_eval_baseline.json`
- added `scripts/compare_domain_task_eval_to_baseline.ps1`

## Why this matters
- domain-task eval without a baseline still leaves too much to memory
- future Gemma-family comparisons should be judged against work the system actually cares about
- this keeps domain-specific comparison local, narrow, and explicit

## Current truth
The current passing domain-task eval results are now pinned as the first baseline for future comparison.
