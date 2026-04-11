# Signal Gateway

The Signal Gateway is the ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into shared schema objects
- persist accepted signal records
- forward accepted work into the current downstream chain
- return the current chain results in one response
- expose list and retrieval surfaces for persisted signal records
- enforce configurable downstream timeout discipline

## Current phase
Phase 2 PostgreSQL-backed ingress service with downstream timeout hardening

## Current endpoints
- `GET /health`
- `POST /signals/ingest`
- `GET /signals`
- `GET /signals/{signal_id}`

## Current downstream chain
`signal-gateway` -> `herald-service` -> `session-engine` -> `eidon-orchestrator`

## Downstream timeout policy
- Herald stays on a tight timeout
- Session Engine stays on a tight timeout
- Orchestrator gets a longer timeout to tolerate local-model cold starts

## Timeout configuration
- `SIGNAL_GATEWAY_HERALD_TIMEOUT_SECONDS=10`
- `SIGNAL_GATEWAY_SESSION_TIMEOUT_SECONDS=10`
- `SIGNAL_GATEWAY_EIDON_TIMEOUT_SECONDS=60`

## Notes
This branch hardens first-run local-model behavior without widening the provider surface or adding routing complexity.
