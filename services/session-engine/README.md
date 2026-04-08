# Session Engine

The Session Engine is the session binding service for Eidonic Core.

## Responsibility
- receive thresholded signal input
- start a session for accepted work
- persist the session record through the current store adapter
- return a session identifier
- expose simple retrieval and listing from the current store

## Current phase
Phase 2 Postgres-ready store contract scaffold

## Current endpoints
- `GET /health`
- `POST /sessions/start`
- `GET /sessions/{session_id}`
- `GET /sessions`

## Session record contract
The current implementation builds a shared `SessionRecord` contract before persistence.

## Session store contract surface
`session-engine` now expects its storage backend to support:
- `backend_name`
- `upsert(record)`
- `get(session_id)`
- `list_recent(limit)`
- `ping()`

## Current adapter implementation
`LocalJsonSessionStore`

## Why this matters
This is the contract surface a future Postgres store will need to satisfy without forcing a service rewrite.

## Local persistence
The current scaffold writes session records to:
`services/session-engine/data/sessions.json`

This file is ignored by Git and remains a temporary local persistence layer.
