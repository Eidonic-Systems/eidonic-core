# Phase 2 Integration Test Health Surfaces

This document records the extension of the full integration test to verify the current service health surfaces.

## Purpose
Move health surface verification from ad hoc manual checks into the standard Phase 2 integration proof.

## Current endpoints under test
- `GET /health` on `signal-gateway`
- `GET /health` on `herald-service`
- `GET /health` on `session-engine`
- `GET /health` on `eidon-orchestrator`

## Why this matters
- health surfaces are operationally important and should be proven automatically
- store-aware health payloads should remain honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies retrieval surfaces, list surfaces, and current service health surfaces.
