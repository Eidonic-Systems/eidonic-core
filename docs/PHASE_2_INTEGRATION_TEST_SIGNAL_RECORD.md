# Phase 2 Integration Test Signal Record

This document records the extension of the full integration test to verify the new signal retrieval surface.

## Purpose
Move signal record verification from manual checking into the standard Phase 2 integration proof.

## Current endpoint under test
- `GET /signals/{signal_id}`

## Why this matters
- accepted ingress should be proven automatically, not only by manual inspection
- this keeps the signal persistence surface honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies signal retrieval, threshold retrieval, threshold list retrieval, chain response, session persistence, artifact persistence, lineage persistence, orchestrator list surfaces, and Herald list surfaces.
