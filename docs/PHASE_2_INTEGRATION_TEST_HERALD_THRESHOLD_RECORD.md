# Phase 2 Integration Test Herald Threshold Record

This document records the extension of the full integration test to verify the new Herald threshold retrieval surface.

## Purpose
Move Herald threshold record verification from manual checking into the standard Phase 2 integration proof.

## Current endpoint under test
- `GET /thresholds/{signal_id}`

## Why this matters
- threshold persistence should be proven automatically, not only by manual inspection
- this keeps the Herald persistence surface honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies threshold retrieval, chain response, session persistence, artifact persistence, lineage persistence, and orchestrator list surfaces.
