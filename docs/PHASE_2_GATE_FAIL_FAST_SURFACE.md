# Phase 2 Gate Fail Fast Surface

This document records the fix that makes the governance gate and top-level Phase 2 gate fail immediately when a child step fails.

## Purpose
Ensure gate success means actual success.

## What changed
- updated `scripts/run_governance_gate.ps1`
- updated `scripts/run_phase2_gate.ps1`

## Why this matters
- a gate that prints success after failed child steps is not a gate
- non-zero child process exit codes must stop the gate immediately
- success output should only appear when every required step actually passed

## Current truth
The governance gate and Phase 2 gate now fail fast on child step failures instead of continuing and printing false success.
