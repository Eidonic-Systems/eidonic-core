# Phase 2 Gate Surface

This document records the first top-level gate for the current Phase 2 build.

## Purpose
Provide one explicit command that answers the real question:
is Phase 2 healthy right now?

## What changed
- added `scripts/run_phase2_gate.ps1`

## Gate coverage
The Phase 2 gate currently runs:
- standard Phase 2 stack start
- provider warmup
- health verification for service, stores, and provider readiness
- governance gate

Because the governance gate already includes:
- governance manifest baseline comparison
- governance manifest change validation
- governance eval surface
- governance eval baseline comparison
- governance rule provenance integration
- full-chain integration verification

the Phase 2 gate becomes the current top-level proof command.

## Why this matters
- Phase 2 discipline should not remain scattered across separate habits
- one top-level gate reduces omission risk
- this gives the repo a single command for current build-health proof

## Current truth
This branch adds a top-level Phase 2 gate only. It does not change runtime behavior, governance rules, routing, or baselines.
