# Phase 2 Stack Runtime Preflight Sequence

This document records the move from optional manual preflight to enforced startup preflight in the Phase 2 stack launcher.

## Purpose
Make the standard stack launcher refuse to boot when obvious runtime prerequisites are missing.

## What changed
- `scripts/start_phase_2_stack.ps1` now runs `scripts/check_phase_2_runtime_prereqs.ps1` first
- startup stops immediately if preflight fails
- service boot, health wait, and provider warmup only run after preflight passes
- startup readout now reflects the real sequence

## Why this matters
- a hardened local stack should not rely on memory for prerequisite checks
- failure before boot is cleaner than failure halfway through startup
- this turns preflight from advice into enforced startup discipline

## Current truth
The standard Phase 2 stack launcher now enforces this order:
1. preflight
2. service boot
3. health wait
4. provider warmup
