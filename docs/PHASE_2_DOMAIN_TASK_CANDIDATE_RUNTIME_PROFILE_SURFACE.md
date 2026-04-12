# Phase 2 Domain Task Candidate Runtime Profile Surface

This document records the first runtime profiling surface for Gemma-family candidates on the domain-task eval set.

## Purpose
Measure whether a Gemma-family candidate provides a real runtime advantage on the system's actual domain tasks, not just on the generic eval loop.

## What changed
- added `scripts/profile_domain_task_candidate_runtime.ps1`

## What the profile measures
- isolated provider warmup time
- isolated domain-task eval duration
- total profile time
- passing or failing domain-task eval status for each model

## Current comparison target
- control model: `gemma3n:e4b`
- candidate model: `gemma3n:e2b`

## Why this matters
- domain-task quality alone is not enough for promotion
- future model judgments should rest on domain-task quality plus domain-task runtime
- this keeps the default model unchanged while producing local runtime evidence on actual system work

## Current truth
This branch adds domain-task runtime evidence gathering only. It does not add routing, change the default model, or alter runtime behavior.
