# Signal Gateway

The Signal Gateway is the ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into shared schema objects
- persist accepted signal records
- forward accepted work into the current downstream chain
- return the current chain results in one response

## Current phase
Phase 2 signal store contract surface scaffold

## Current endpoints
- `GET /health`
- `POST /signals/ingest`
- `GET /signals/{signal_id}`

## Current downstream chain
`signal-gateway` → `herald-service` → `session-engine` → `eidon-orchestrator`

## Store contract surface
The current implementation now uses an explicit local store adapter for signal persistence instead of keeping JSON persistence inline in the main service file.

## Local persistence
The current scaffold writes signal records to:
`services/signal-gateway/data/signals.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real durable backend is introduced.

## Environment configuration
If a repo root `.env` file is present, `signal-gateway` loads these values:
- `HERALD_BASE_URL`
- `SESSION_ENGINE_BASE_URL`
- `EIDON_BASE_URL`

## Notes
This is a temporary local signal persistence step, not the final ingress governance, queueing, or durable transport layer.
