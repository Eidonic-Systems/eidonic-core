# Signal Gateway

The Signal Gateway is the first ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into SignalEvent objects
- reject malformed ingress
- pass valid signals to thresholding and session logic

## Current phase
Phase 1 scaffold only

## Current endpoints
- `GET /health`
- `POST /signals/ingest`

## Notes
This service currently accepts and echoes valid signal input.
Thresholding, session binding, persistence, and routing are not implemented yet.
