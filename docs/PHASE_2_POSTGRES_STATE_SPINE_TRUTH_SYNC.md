# Phase 2 Postgres State Spine Truth Sync

This document records the repo-level documentation sync after PostgreSQL-backed pilots were merged across the full Phase 2 state spine.

## Purpose
Make the top-level repo surface and service docs match the current proven PostgreSQL-backed build state.

## Why this matters
- the repo should not describe local JSON as the current proven primary persistence layer once PostgreSQL pilots are merged on `main`
- `.env.example` should reflect the current proven backend posture
- service READMEs should describe the actual current backend truth instead of the earlier local-only scaffold state

## Current truth
The current proven Phase 2 stack runs Signal Gateway, Herald, Session Engine, and Orchestrator on PostgreSQL, with local JSON adapters still present as fallback implementations.
