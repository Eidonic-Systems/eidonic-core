# Phase 2 Integration Test Signal List Surfaces

This document records the extension of the full integration test to verify the new Signal Gateway list surface.

## Purpose
Move signal list verification from manual checking into the standard Phase 2 integration proof.

## Current endpoint under test
- `GET /signals`

## Why this matters
- signal list surfaces should be proven automatically, not only by manual inspection
- this keeps the Signal Gateway retrieval surface honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies signal retrieval, signal list retrieval, threshold retrieval, threshold list retrieval, chain response, session persistence, artifact persistence, lineage persistence, orchestrator list surfaces, and Herald list surfaces.
