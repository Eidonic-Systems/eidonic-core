# Phase 2 State Gate Surface

This document records the point where the local PostgreSQL state layer became part of the required Phase 2 proof path.

## Purpose
Turn state discipline from optional utility scripts into required gate coverage.

## What changed
- updated `scripts/run_phase2_gate.ps1`

## Added gate coverage
The top-level Phase 2 gate now runs:
- PostgreSQL database bootstrap
- PostgreSQL schema bootstrap
- PostgreSQL schema drift validation

before continuing to the rest of the normal proof path.

## Why this matters
- a stateful core should not treat database and schema checks as optional hygiene
- state bootstrap and schema validation belong inside the actual proof path
- this makes persistence discipline part of required proof instead of side utility work

## Current truth
This branch strengthens the top-level gate only.

It does not:
- change runtime behavior
- add new persistence fields
- widen governance behavior
- expand CI behavior
