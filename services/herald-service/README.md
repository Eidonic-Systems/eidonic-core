# Herald Service

The Herald Service is the current threshold review service for Eidonic Core.

## Responsibility
- receive a signal review request
- apply the current threshold scaffold result
- persist a threshold record
- return a threshold review result
- expose list and retrieval surfaces for persisted threshold records

## Current phase
Phase 2 PostgreSQL-backed threshold service

## Current endpoints
- `GET /health`
- `POST /threshold/check`
- `GET /thresholds`
- `GET /thresholds/{signal_id}`

## Threshold store contract surface
`herald-service` expects its storage backend to support:
- `backend_name`
- `upsert(record)`
- `get(signal_id)`
- `list_recent(limit)`
- `ping()`

## Current adapter implementations
- `PostgresThresholdStore`
- `LocalJsonThresholdStore`

## Current proven backend
The current proven Phase 2 stack runs Herald on PostgreSQL.

## Backend selection
Choose the active backend through environment variables:
- `HERALD_STORE_BACKEND=postgres` or `local_json`
- `HERALD_POSTGRES_DSN=postgresql://...`

## Notes
Local JSON remains available as fallback.
