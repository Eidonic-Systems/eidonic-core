# Phase 2 Session Engine Local Persistence

This document records the first temporary persistence layer for `session-engine`.

## Purpose
Make a started session exist somewhere real before introducing a database.

## Current storage
`services/session-engine/data/sessions.json`

## Behavior
- `POST /sessions/start` creates or updates a session record
- `GET /sessions/{session_id}` returns the stored session record
- storage is local JSON only

## Why this exists
This is the non-stupid order of work:
1. prove the session behavior
2. inspect the stored shape
3. replace the JSON store with Postgres later

## Current truth
This is only temporary local persistence.
There is no locking, no concurrent write protection, and no relational querying yet.
