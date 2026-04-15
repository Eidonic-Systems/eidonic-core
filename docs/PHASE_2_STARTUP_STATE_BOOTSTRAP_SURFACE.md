# Phase 2 Startup State Bootstrap Surface

This document records the point where the runtime startup path became responsible for enforcing PostgreSQL state discipline before service startup.

## Purpose
Bring the startup path up to the same state discipline standard as the top-level proof path.

## What changed
- updated `scripts/start_phase_2_stack.ps1`

## Added startup coverage
The Phase 2 startup path now runs:
- PostgreSQL database bootstrap
- PostgreSQL schema bootstrap
- PostgreSQL schema drift validation

before continuing to service startup.

## Why this matters
- the startup path should not be weaker than the proof path
- a stateful core should fail before service startup if database or schema state is wrong
- this turns state discipline into a startup requirement instead of a later discovery

## Current truth
This branch strengthens the startup path only.

It does not:
- change runtime behavior inside services
- add new persistence fields
- widen governance behavior
- expand CI behavior
