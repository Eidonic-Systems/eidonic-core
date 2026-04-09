# Herald Service

The Herald Service is the current threshold review service for Eidonic Core.

## Responsibility
- receive a signal review request
- apply the current threshold scaffold result
- persist a threshold record
- return a threshold review result
- expose list and retrieval surfaces for persisted threshold records

## Current phase
Phase 2 threshold store contract list surface scaffold

## Current endpoints
- `GET /health`
- `POST /threshold/check`
- `GET /thresholds`
- `GET /thresholds/{signal_id}`

## Store contract surface
The current implementation uses an explicit local store adapter for threshold persistence instead of keeping JSON persistence inline in the main service file.

## Local persistence
The current scaffold writes threshold records to:
`services/herald-service/data/thresholds.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real durable backend is introduced.

## Notes
This is a temporary local threshold persistence step, not the final review, provenance, or witness layer.
