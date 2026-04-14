# Phase 2 Governance Gate Surface

This document records the first single-command governance gate for Eidonic Core.

## Purpose
Provide one explicit command that runs the current governance discipline checks in the correct order.

## What changed
- added `scripts/run_governance_gate.ps1`

## Gate coverage
The governance gate currently runs:
- governance manifest baseline comparison
- governance manifest change validation
- governance eval surface
- governance eval baseline comparison
- governance rule provenance integration test
- full-chain integration test

## Why this matters
- governance discipline should not remain scattered across separate commands
- a single gate reduces operator sloppiness and omission risk
- this creates one bounded command that proves governance discipline end to end

## Current truth
This branch adds a governance gate only. It does not change governance behavior, rules, or baselines.
