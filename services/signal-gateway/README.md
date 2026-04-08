# Signal Gateway

The Signal Gateway is the first ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into SignalEvent objects
- reject malformed ingress
- pass valid signals to thresholding and session logic

## Current phase
Phase 2 chained scaffold

## Current endpoints
- `GET /health`
- `POST /signals/ingest`

## Current behavior
This service now performs the first downstream handoff chain:
1. accept a valid `SignalEvent`
2. call `herald-service` at `/threshold/check`
3. if Herald returns `threshold_result = "pass"`, call `session-engine` at `/sessions/start`
4. return both downstream results in the gateway response

## Environment variables
- `HERALD_SERVICE_BASE_URL` defaults to `http://127.0.0.1:8001`
- `SESSION_ENGINE_BASE_URL` defaults to `http://127.0.0.1:8002`

## Notes
Clarification, consent checks, persistence, retries, and orchestration routing are not implemented yet.
This is still a narrow first chain, not a full service graph.
