# Phase 2 Domain Task Routing Pilot Surface

This document records the first narrow runtime routing implementation for Gemma-family models.

## Purpose
Test a small, logged, reversible routing pilot for a narrow domain-task slice without changing the control model.

## What changed
- updated `services/eidon-orchestrator/app/provider.py`
- updated `.env.example`
- added `tests/integration/test_domain_task_routing_pilot_surface.ps1`
- updated `services/eidon-orchestrator/README.md`

## Pilot shape
- control model remains `gemma3n:e4b`
- candidate route target is `gemma3n:e2b`
- only a small allowlist of domain-task patterns is route-eligible
- candidate failure falls back to the control model
- the chosen model is reflected in persisted provenance

## Why this matters
- policy and decision records now justify a narrow routing pilot
- the pilot stays understandable and reversible
- this tests routing behavior without introducing broad dynamic model selection

## Current truth
This branch adds a narrow routing pilot only. It does not replace the control model and it does not introduce a general-purpose router.
