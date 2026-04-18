# Phase 2 Uvicorn Compatibility Batch

This document records the second bounded compatibility batch from the current Dependabot intake.

## Purpose
Update `uvicorn` in one isolated batch before touching heavier framework dependencies.

## What changed
- updated `services/eidon-orchestrator/requirements.txt`
- updated `services/signal-gateway/requirements.txt`
- updated `services/session-engine/requirements.txt`
- updated `services/herald-service/requirements.txt`

## Update scope
- `uvicorn` from `0.30.6` to `0.44.0`

## Why this batch is bounded
`uvicorn` is shared across all four services, but it is still a cleaner compatibility slice than `fastapi` or `pydantic`, which are more likely to drag request and model semantics with them.

## Current truth
This branch is a compatibility batch only.

It does not:
- widen framework upgrades beyond `uvicorn`
- change governance behavior
- change routing behavior
- change CI behavior
