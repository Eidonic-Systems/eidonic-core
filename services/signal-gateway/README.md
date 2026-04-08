# Signal Gateway

The Signal Gateway is the ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into shared schema objects
- forward accepted work into the current downstream chain
- return the current chain results in one response

## Current phase
Phase 2 chained scaffold

## Current endpoints
- `GET /health`
- `POST /signals/ingest`

## Current downstream chain
`signal-gateway` → `herald-service` → `session-engine` → `eidon-orchestrator`

## Notes
This service now performs the first full downstream HTTP chain for the current scaffold.
Persistence, retries, queueing, governance, and deeper orchestration logic are not implemented yet.
