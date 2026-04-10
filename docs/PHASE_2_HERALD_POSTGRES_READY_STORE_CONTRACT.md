# Phase 2 Herald Postgres-Ready Store Contract

This document records the hardening of the Herald threshold store contract toward the same future-backend posture already used in Session Engine.

## Purpose
Move Herald from a temporary local list contract toward a more stable store contract surface without introducing a real database yet.

## Current contract surface
- `upsert(record)`
- `get(signal_id)`
- `list_recent(limit=50)`
- `ping()`

## Why this matters
- this keeps Herald aligned with the architectural posture already used in Session Engine
- list surfaces should not remain an unbounded ad hoc contract when a more durable backend is expected later
- this improves contract discipline without changing current runtime behavior

## Current truth
The implementation remains local JSON only.
The improvement here is contract maturity, not a new backend.
