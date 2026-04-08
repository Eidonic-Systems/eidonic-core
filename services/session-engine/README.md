# Session Engine

The Session Engine is the session binding service for Eidonic Core.

## Responsibility
- receive thresholded signal input
- start a session for accepted work
- persist the session record in the current local store
- return a session identifier

## Current phase
Phase 2 local persistence scaffold

## Current endpoints
- `GET /health`
- `POST /sessions/start`
- `GET /sessions/{session_id}`

## Local persistence
The current scaffold writes session records to:
`services/session-engine/data/sessions.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real database is introduced.

## Notes
This is a local JSON persistence step, not the final state layer.
Persistence currently supports simple upsert-by-session-id behavior and basic retrieval by session ID.
