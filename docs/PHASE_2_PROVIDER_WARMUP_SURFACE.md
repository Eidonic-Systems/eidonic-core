# Phase 2 Provider Warmup Surface

This document records the addition of explicit provider warmup and readiness surfaces in Orchestrator.

## Purpose
Make local-model warm state visible and controllable instead of relying on accidental first-use behavior.

## What changed
- added provider `warm()` capability
- added `POST /provider/warm` in Orchestrator
- added `provider.ready` in Orchestrator health
- added `scripts/warm_eidon_provider.ps1` for deterministic local warmup

## Why this matters
- cold-start tolerance alone is weaker than explicit readiness
- a bulletproof local system should know whether the provider is warmed
- this keeps the warmup seam narrow and observable before any routing complexity appears
