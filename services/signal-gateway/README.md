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

## Environment configuration
If a repo root `.env` file is present, `signal-gateway` loads these values:
- `HERALD_BASE_URL`
- `SESSION_ENGINE_BASE_URL`
- `EIDON_BASE_URL`

Copy `.env.example` to `.env` and change the values there if you need different downstream service addresses.

## Notes
This service performs the current full downstream HTTP chain for the scaffold.
Persistence, retries, queueing, governance, and deeper orchestration logic are not implemented yet.
