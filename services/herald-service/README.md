# Herald Service

The Herald Service is the current threshold review service for Eidonic Core.

## Responsibility
- receive a signal review request
- apply the current threshold scaffold result
- persist a threshold record
- return a threshold review result
- expose list and retrieval surfaces for persisted threshold records

## Current phase
Phase 2 Postgres backend pilot

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
- `LocalJsonThresholdStore`
- `PostgresThresholdStore`

## Backend selection
Choose the active backend through environment variables:
- `HERALD_STORE_BACKEND=local_json` or `postgres`
- `HERALD_POSTGRES_DSN=postgresql://...`

## Why this matters
This is the second real durable-backend pilot for the Phase 2 scaffold. The goal is to prove a database-backed threshold store without changing HTTP behavior.

## Notes
Local JSON remains available as fallback during the pilot.
