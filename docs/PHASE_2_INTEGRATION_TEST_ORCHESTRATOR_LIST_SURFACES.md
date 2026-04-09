# Phase 2 Integration Test Orchestrator List Surfaces

This document records the extension of the full integration test to verify the new orchestrator list surfaces.

## Purpose
Move orchestrator list surface verification from manual checking into the standard Phase 2 integration proof.

## Current endpoints under test
- `GET /artifacts`
- `GET /lineage`

## Why this matters
- list surfaces should be proven automatically, not only by manual inspection
- this keeps the retrieval surface honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies chain response, session persistence, artifact persistence, lineage persistence, and orchestrator list surfaces.
