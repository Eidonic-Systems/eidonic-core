# Session Engine

The Session Engine is the session binding service for Eidonic Core.

## Responsibility
- receive thresholded signal input
- start a session for accepted work
- persist the session record through the current store adapter
- return a session identifier

## Current phase
Phase 2 session store adapter scaffold

## Current endpoints
- `GET /health`
- `POST /sessions/start`
- `GET /sessions/{session_id}`

## Session record contract
The current implementation builds a shared `SessionRecord` contract before persistence.

## Session store adapter
`session-engine` now writes through a `SessionStore` boundary.

The current adapter implementation is:
`LocalJsonSessionStore`

## Local persistence
The current scaffold writes session records to:
`services/session-engine/data/sessions.json`

This file is ignored by Git and acts as a temporary local persistence layer until a real database adapter is introduced.

## Notes
This is still temporary local persistence, but the storage mechanism is now separated from the session record shape and service behavior.
