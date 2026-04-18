# Phase 2 HTTPX Compatibility Batch

This document records the first bounded compatibility update batch for a currently visible Dependabot library family.

## Purpose
Take the narrowest compatibility-sensitive dependency update first instead of mixing multiple framework updates into one branch.

## What changed
- updated `services/eidon-orchestrator/requirements.txt`
- updated `services/signal-gateway/requirements.txt`

## Update scope
- `httpx` from `0.27.2` to `0.28.1`

## Why this batch is narrow
The current repo surface only uses `httpx` directly in:
- `eidon-orchestrator`
- `signal-gateway`

That makes `httpx` a smaller blast-radius batch than FastAPI, Pydantic, or Uvicorn.

## Current truth
This branch is a compatibility batch only.

It does not:
- widen framework upgrades beyond `httpx`
- change governance behavior
- change startup behavior
- change CI behavior
