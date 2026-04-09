# Herald Service

The Herald Service is the current threshold review service for Eidonic Core.

## Responsibility
- receive a signal review request
- apply the current threshold scaffold result
- persist a threshold record
- return a threshold review result

## Current phase
Phase 2 threshold record contract scaffold

## Current endpoints
- `GET /health`
- `POST /threshold/check`
- `GET /thresholds/{signal_id}`

## Threshold record contract
The current implementation builds and stores a shared `ThresholdRecord` contract before writing it to the local JSON store.

## Local persistence
The current scaffold writes threshold records to:
`services/herald-service/data/thresholds.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real durable backend is introduced.

## Notes
This is a temporary local threshold persistence step, not the final review, provenance, or witness layer.

