# Phase 2 Governance Enforcement Pilot Surface

This document records the first narrow runtime governance enforcement pilot in Eidonic Core.

## Purpose
Prove that the system can take a small set of governance outcomes on purpose and persist them cleanly without pretending a full Guardian engine already exists.

## What changed
- updated shared schema models to allow `not_invoked` provider status
- updated Orchestrator to apply a narrow governance enforcement pilot before provider invocation
- added `tests/integration/test_governance_enforcement_pilot_surface.ps1`

## Pilot scope
The pilot is intentionally narrow.

Active outcomes:
- `allow` for normal safe orchestration
- `fallback` for provider failure through the existing failure path
- `refuse` for explicit impersonation-style requests
- `hold` for explicitly ambiguous command input

## Why this matters
- policy, eval, and provenance now exist
- the repo is ready for a small enforcement pilot
- narrow enforcement is more honest than pretending a full Guardian engine is live

## Current truth
This branch adds a narrow governance enforcement pilot only. It does not introduce a full Guardian runtime.
