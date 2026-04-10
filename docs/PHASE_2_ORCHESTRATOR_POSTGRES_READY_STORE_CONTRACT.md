# Phase 2 Orchestrator Postgres-Ready Store Contract

This document records the hardening of the Orchestrator store contracts toward the same future-backend posture already used in Session Engine.

## Purpose
Move Orchestrator from temporary local list contracts toward more stable store contract surfaces without introducing a real database yet.

## Current contract surface
- artifact store: `upsert(record)`, `get(artifact_id)`, `list_recent(limit=50)`, `ping()`
- lineage store: `upsert(record)`, `get_by_artifact_id(artifact_id)`, `list_recent(limit=50)`, `ping()`

## Why this matters
- this keeps Orchestrator aligned with the architectural posture already used in Session Engine
- list surfaces should not remain unbounded ad hoc contracts when a more durable backend is expected later
- this improves contract discipline without changing current runtime behavior

## Current truth
The implementation remains local JSON only.
The improvement here is contract maturity, not a new backend.
