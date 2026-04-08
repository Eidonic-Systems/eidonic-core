# Phase 2 Session Store Adapter

This document records the first storage adapter boundary for `session-engine`.

## Purpose
Separate session persistence behavior from the current JSON file implementation.

## Current boundary
`SessionStore`

## Current implementation
`LocalJsonSessionStore`

## Why this matters
- storage should be swappable
- `session-engine` should not be fused to JSON file mechanics
- Postgres can later replace the adapter instead of forcing a service rewrite

## Current truth
The storage backend is still temporary local JSON.
The improvement here is architectural: persistence now sits behind an adapter boundary.
