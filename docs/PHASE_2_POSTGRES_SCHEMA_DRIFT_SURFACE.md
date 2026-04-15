# Phase 2 PostgreSQL Schema Drift Surface

This document records the first explicit schema drift validation surface for the local Phase 2 PostgreSQL state layer.

## Purpose
Verify not only that the required tables exist, but that they still contain the columns the core depends on.

## What changed
- added `scripts/validate_phase2_postgres_schema_drift.ps1`

## What the script does
- reads the repo `.env`
- finds a PostgreSQL DSN
- queries `information_schema.columns`
- validates required columns on:
  - `artifact_records`
  - `artifact_lineage_records`

## Why this matters
- table existence alone is too weak for a stateful core
- the persistence layer depends on provider, routing, governance, and rule provenance fields
- this makes schema shape validation a first-class local state check

## Current truth
This branch adds PostgreSQL schema drift validation only.

It does not:
- change runtime behavior
- widen governance behavior
- add CI behavior
- replace the existing database or schema bootstrap scripts
