# Phase 2 Integration Test Provider Surface

This document records the extension of the full integration test to verify the Orchestrator provider contract surface.

## Purpose
Move provider-surface verification into the standard Phase 2 integration proof.

## Current endpoint under test
- `GET /health` on `eidon-orchestrator`

## Provider fields under test
- `provider.status`
- `provider.backend`
- `provider.model`

## Why this matters
- the provider contract should be proven automatically, not trusted implicitly
- the stub provider is part of the current live Orchestrator surface
- provider health should stay honest before any real local model adapter is introduced

## Current truth
The standard proof now verifies that Orchestrator exposes a healthy stub provider through its health surface.
