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
Phase 2 PostgreSQL-backed ingress service

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
- `PostgresSignalStore`
- `LocalJsonSignalStore`

## Current proven backend
The current proven Phase 2 stack runs Signal Gateway on PostgreSQL.

## Backend selection
Choose the active backend through environment variables:
- `SIGNAL_GATEWAY_STORE_BACKEND=postgres` or `local_json`
- `SIGNAL_GATEWAY_POSTGRES_DSN=postgresql://...`

## Notes
Local JSON remains available as fallback.
