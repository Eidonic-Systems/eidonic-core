# Session Engine

The Session Engine is the session binding service for Eidonic Core.

## Responsibility
- receive thresholded signal input
- start a session for accepted work
- persist the session record in the current local store
- return a session identifier

## Current phase
Phase 2 session record contract scaffold

## Current endpoints
- `GET /health`
- `POST /sessions/start`
- `GET /sessions/{session_id}`

## Session record contract
The current implementation builds and stores a shared `SessionRecord` contract before writing it to the local JSON store.

## Local persistence
The current scaffold writes session records to:
`services/session-engine/data/sessions.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real database is introduced.

## Notes
This is a local JSON persistence step, not the final state layer.
The current goal is to keep the session record shape stable while the storage backend remains temporary.
