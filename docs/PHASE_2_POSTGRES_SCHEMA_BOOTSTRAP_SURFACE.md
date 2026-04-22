# Phase 2 PostgreSQL Schema Bootstrap Surface

This document records the first explicit schema bootstrap surface for the local Phase 2 PostgreSQL state layer.

## Purpose
Make schema creation and verification explicit instead of relying only on incidental side effects.

## What changed
- added `scripts/bootstrap_phase2_postgres_schema.ps1`

## What the script does
- reads the repo `.env`
- finds a PostgreSQL DSN
- loads the Orchestrator environment from `.env`
- imports `app.main` through the Orchestrator venv to trigger store initialization
- verifies the required PostgreSQL tables exist:
  - `artifact_records`
  - `artifact_lineage_records`

## Why this matters
- a stateful core should have an explicit schema bootstrap path
- fresh-machine setup should not depend on guessing whether table creation happened incidentally
- this makes schema existence a first-class local bootstrap surface

## Current truth
This branch adds PostgreSQL schema bootstrap automation only.

It does not:
- change runtime behavior
- widen governance behavior
- add CI behavior
- replace the existing database bootstrap script

## Repeated-run proof

The repeated local bootstrap path is now proved by:
- `scripts/validate_phase2_postgres_bootstrap_idempotence.ps1`
