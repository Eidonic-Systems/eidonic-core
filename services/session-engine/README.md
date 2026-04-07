# Session Engine

The Session Engine is the first session binding service for Eidonic Core.

## Responsibility
- receive thresholded signal input
- start a session for accepted work
- return a session identifier
- later hold persistence, stage tracking, and closure logic

## Current phase
Phase 1 scaffold only

## Current endpoints
- `GET /health`
- `POST /sessions/start`

## Notes
This service currently accepts and echoes valid session start input.
Persistence, stage progression, working memory linkage, and closure logic are not implemented yet.
