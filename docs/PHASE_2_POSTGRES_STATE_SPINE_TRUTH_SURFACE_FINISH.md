# Phase 2 Postgres State Spine Truth Surface Finish

This document records the remaining repo-level and service-level truth sync after the PostgreSQL-backed state spine was proven on `main`.

## Purpose
Finish the doc surfaces that still described local JSON as the active implementation after PostgreSQL pilots were merged across the Phase 2 chain.

## Why this matters
- `AGENTS.md` should not describe local JSON as the current verified persistence layer anymore
- `.env.example` should not leave Orchestrator defaulting to `local_json` once the proven stack is fully PostgreSQL-backed
- service READMEs should describe PostgreSQL as the current proven backend while still naming local JSON as fallback

## Current truth
Signal Gateway, Herald, Session Engine, and Orchestrator are now proven on PostgreSQL in the current Phase 2 stack. Local JSON adapters remain available as fallback implementations.
