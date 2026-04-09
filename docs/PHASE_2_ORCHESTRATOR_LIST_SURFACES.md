# Phase 2 Orchestrator List Surfaces

This document records the first explicit list surfaces for persisted orchestrator artifacts and lineage records.

## Purpose
Make persisted orchestrator records inspectable as collections instead of only as single-record lookups.

## Current endpoints
- `GET /artifacts`
- `GET /artifacts/{artifact_id}`
- `GET /lineage`
- `GET /lineage/{artifact_id}`

## Why this matters
- persisted records should be reviewable as a set, not only by exact identifier
- this makes the current JSON scaffold easier to inspect and verify
- later dashboards and operator surfaces need a basic list surface before any richer filtering exists

## Current truth
This is still temporary local JSON persistence.
The improvement here is retrieval surface completeness, not a new backend.
