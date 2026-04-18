# Phase 2 FastAPI Compatibility Batch

This document records the next bounded compatibility batch from the current Dependabot intake.

## Purpose
Update `fastapi` in one isolated batch before touching `pydantic`.

## What changed
- updated `services/eidon-orchestrator/requirements.txt`
- updated `services/signal-gateway/requirements.txt`
- updated `services/session-engine/requirements.txt`
- updated `services/herald-service/requirements.txt`

## Update scope
- `fastapi` from `0.115.0` to `0.136.0`

## Why this batch is bounded
`fastapi` is shared across all four services, but it is still a cleaner compatibility slice than `pydantic`, which is more likely to drag validation-model behavior with it.

## Current truth
This branch is a compatibility batch only.

It does not:
- widen framework upgrades beyond `fastapi`
- change governance behavior
- change routing behavior
- change CI behavior
