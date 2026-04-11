# Phase 2 Provider Failure Semantics

This document records the hardening of provider failure behavior in Orchestrator.

## Purpose
Make provider failures explicit, structured, and traceable instead of collapsing them into vague runtime errors.

## What changed
- explicit provider failure classes
- persisted provider failure truth in artifact and lineage records
- structured `provider_failed` orchestration responses

## Why this matters
- provenance without failure semantics is incomplete
- future model and provider comparisons require reliable failure traces
- this keeps the provider seam honest before adding routing or more model complexity
