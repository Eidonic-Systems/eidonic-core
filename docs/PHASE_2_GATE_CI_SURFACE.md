# Phase 2 Gate CI Surface

This document records the first CI surface for the Phase 2 gate.

## Purpose
Run the existing top-level Phase 2 gate through GitHub Actions instead of relying only on manual local execution.

## What changed
- added `.github/workflows/phase2-gate.yml`

## CI strategy
The first CI surface is intentionally narrow and honest.

It uses:
- GitHub Actions
- a self-hosted Windows runner
- the existing `scripts/run_phase2_gate.ps1` command

It does not attempt to recreate the current Phase 2 runtime stack in a generic hosted runner.

## Why this matters
- the Phase 2 gate is now the top-level proof command
- CI should call the real gate instead of reimplementing it in workflow YAML
- a self-hosted runner is the honest first step for a stack that depends on local provider and stack conditions

## Expected runner labels
The workflow currently expects a self-hosted runner with:
- `self-hosted`
- `windows`
- `eidonic-phase2`

## Current truth
This branch adds a CI surface for the existing Phase 2 gate only.

It does not change:
- runtime behavior
- governance rules
- routing behavior
- the gate logic itself
