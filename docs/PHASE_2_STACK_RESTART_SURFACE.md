# Phase 2 Stack Restart Surface

This document records the first bounded restart surface for the local Phase 2 stack.

## Purpose
Provide one explicit recovery command for a messy local stack.

## What changed
- added `scripts/restart_phase_2_stack.ps1`

## What the script does
- stops stale Phase 2 service processes
- clears the known Phase 2 service ports
- reruns `scripts/start_phase_2_stack.ps1`
- optionally reruns `scripts/run_phase2_gate.ps1 -SkipStackStart`

## Covered ports
- `8000`
- `8001`
- `8002`
- `8003`

## Why this matters
- local recovery should be more deterministic than manually closing windows and guessing
- startup should have a bounded restart surface when the stack gets messy
- this reduces operational friction without hiding what the machine is doing

## Current truth
This branch adds a local stack restart surface only.

It does not:
- change runtime behavior
- add new persistence fields
- widen governance behavior
- expand CI behavior
