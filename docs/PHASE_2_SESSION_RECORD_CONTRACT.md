# Phase 2 Session Record Contract

This document records the first explicit session record contract for `session-engine`.

## Purpose
Separate the canonical session record shape from the current JSON storage mechanism.

## Current contract
The shared `SessionRecord` model now defines the current canonical shape for persisted sessions.

## Why this matters
- record shape should not be fused to storage details
- the JSON store is temporary
- Postgres can replace the JSON backend later without redefining the session itself

## Current storage backend
`local_json`

## Current truth
This is still a temporary local persistence layer.
The improvement here is structural: session records now have an explicit shared contract.
