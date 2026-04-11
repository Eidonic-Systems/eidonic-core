# Signal Gateway

The Signal Gateway is the ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into shared schema objects
- persist accepted signal records
- forward accepted work into the current downstream chain
- return the current chain results in one response
- expose list and retrieval surfaces for persisted signal records

## Current phase
Phase 2 Postgres backend pilot

## Current endpoints
- `GET /health`
- `POST /signals/ingest`
- `GET /signals`
- `GET /signals/{signal_id}`

## Current downstream chain
`signal-gateway` -> `herald-service` -> `session-engine` -> `eidon-orchestrator`

## Signal store contract surface
`signal-gateway` expects its storage backend to support:
- `backend_name`
- `upsert(record)`
- `get(signal_id)`
- `list_recent(limit)`
- `ping()`

## Current adapter implementations
- `LocalJsonSignalStore`
- `PostgresSignalStore`

## Backend selection
Choose the active backend through environment variables:
- `SIGNAL_GATEWAY_STORE_BACKEND=local_json` or `postgres`
- `SIGNAL_GATEWAY_POSTGRES_DSN=postgresql://...`

## Why this matters
This is the third real durable-backend pilot for the Phase 2 scaffold. The goal is to prove a database-backed ingress store without changing HTTP behavior.

## Notes
Local JSON remains available as fallback during the pilot.
