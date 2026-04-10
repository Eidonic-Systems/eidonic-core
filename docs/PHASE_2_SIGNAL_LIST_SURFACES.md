# Phase 2 Signal List Surfaces

This document records the first explicit list surface for persisted signal records.

## Purpose
Make persisted signal records inspectable as a collection instead of only as single-record lookups.

## Current endpoints
- `GET /signals`
- `GET /signals/{signal_id}`

## Why this matters
- persisted signal records should be reviewable as a set, not only by exact signal identifier
- this makes the current JSON scaffold easier to inspect and verify
- later dashboards and operator surfaces need a basic list surface before richer filtering exists

## Current truth
This is still temporary local JSON persistence.
The improvement here is retrieval surface completeness, not a new backend.
