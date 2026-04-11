# Session Engine

The Session Engine is the session binding service for Eidonic Core.

## Responsibility
- receive thresholded signal input
- start a session for accepted work
- persist the session record through the current store adapter
- return a session identifier
- expose simple retrieval and listing from the current store

## Current phase
Phase 2 PostgreSQL-backed session service

## Current endpoints
- `GET /health`
- `POST /sessions/start`
- `GET /sessions/{session_id}`
- `GET /sessions`

## Session store contract surface
`session-engine` expects its storage backend to support:
- `backend_name`
- `upsert(record)`
- `get(session_id)`
- `list_recent(limit)`
- `ping()`

## Current adapter implementations
- `PostgresSessionStore`
- `LocalJsonSessionStore`

## Current proven backend
The current proven Phase 2 stack runs Session Engine on PostgreSQL.

## Backend selection
Choose the active backend through environment variables:
- `SESSION_ENGINE_STORE_BACKEND=postgres` or `local_json`
- `SESSION_ENGINE_POSTGRES_DSN=postgresql://...`

## Notes
Local JSON remains available as fallback.
