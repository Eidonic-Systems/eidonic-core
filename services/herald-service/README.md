# Herald Service

The Herald Service is the current threshold review service for Eidonic Core.

## Responsibility
- receive a signal review request
- apply the current threshold scaffold result
- persist a threshold record
- return a threshold review result
- expose list and retrieval surfaces for persisted threshold records

## Current phase
Phase 2 Postgres-ready threshold store contract scaffold

## Current endpoints
- `GET /health`
- `POST /threshold/check`
- `GET /thresholds`
- `GET /thresholds/{signal_id}`

## Store contract surface
The current implementation uses an explicit threshold store contract with `upsert`, `get`, `list_recent(limit)`, and `ping()` semantics.

The active implementation is still `LocalJsonThresholdStore`, but the contract surface is now shaped for a future durable backend without changing the current runtime behavior.

## Local persistence
The current scaffold writes threshold records to:
`services/herald-service/data/thresholds.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real durable backend is introduced.

## Notes
This is still not a database-backed review, provenance, or witness layer.
