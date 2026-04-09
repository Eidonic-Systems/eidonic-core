# Phase 2 Integration Test Herald List Surfaces

This document records the extension of the full integration test to verify the new Herald threshold list surface.

## Purpose
Move Herald threshold list verification from manual checking into the standard Phase 2 integration proof.

## Current endpoint under test
- `GET /thresholds`

## Why this matters
- Herald list surfaces should be proven automatically, not only by manual inspection
- this keeps the Herald retrieval surface honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies threshold retrieval, threshold list retrieval, chain response, session persistence, artifact persistence, lineage persistence, and orchestrator list surfaces.
