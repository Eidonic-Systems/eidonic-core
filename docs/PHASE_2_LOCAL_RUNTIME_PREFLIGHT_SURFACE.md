# Phase 2 Local Runtime Preflight Surface

This document records the addition of a local runtime preflight surface for the Phase 2 stack.

## Purpose
Verify key runtime prerequisites before startup instead of learning about missing dependencies only after boot attempts.

## What changed
- added `scripts/check_phase_2_runtime_prereqs.ps1`
- preflight now verifies required `.env` keys
- preflight now verifies PostgreSQL reachability
- preflight now verifies Ollama reachability when selected
- preflight now verifies configured local model presence
- preflight now verifies the Orchestrator Python environment is present

## Why this matters
- clear failure after startup is good
- clear detection before startup is better
- this makes local runtime setup more intentional and less ritualistic

## Current truth
The Phase 2 local workflow now has an explicit preflight step before stack startup.
