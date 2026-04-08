# Phase 2 Postgres-Ready Session Store Contract

This document records the first Postgres-ready contract surface for `session-engine` storage.

## Purpose
Define the operations a durable session backend must support before introducing Postgres.

## Current session store contract
- `backend_name`
- `upsert(record)`
- `get(session_id)`
- `list_recent(limit)`
- `ping()`

## Current implementation
`LocalJsonSessionStore`

## Why this matters
- Postgres should be a backend replacement, not a service rewrite
- the service should depend on a stable storage surface
- health, lookup, and listing behavior should already have defined meanings

## Current truth
This branch does not introduce Postgres.
It only defines the contract surface a future Postgres adapter will need to implement.
