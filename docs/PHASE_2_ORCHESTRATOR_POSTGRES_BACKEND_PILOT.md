# Phase 2 Orchestrator Postgres Backend Pilot

This document records the fourth real durable-backend pilot in the Phase 2 scaffold.

## Purpose
Prove the existing Orchestrator store contracts against PostgreSQL without changing HTTP behavior or widening the runtime scope.

## Backend strategy
- keep local JSON stores as fallback
- add PostgreSQL stores for artifact and lineage records
- select backend by environment variable
- keep the current routes and response shapes unchanged

## Why this matters
- Orchestrator is the final obvious durable-backend seam in the Phase 2 chain
- this completes the first real database-backed state spine before provider/runtime work
- this reduces architectural risk before moving beyond persistence hardening

## Current truth
This branch introduces real PostgreSQL-backed stores only for Orchestrator.
