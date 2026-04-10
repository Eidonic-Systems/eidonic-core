# Phase 2 Integration Test Session List Surfaces

This document records the extension of the full integration test to verify the Session Engine list surface.

## Purpose
Move session list verification from manual checking into the standard Phase 2 integration proof.

## Current endpoint under test
- `GET /sessions`

## Why this matters
- session list surfaces should be proven automatically, not only by manual inspection
- this keeps the Session Engine retrieval surface honest after merge
- the integration test should reflect the current live scaffold truth

## Current truth
The test now verifies signal retrieval, signal list retrieval, threshold retrieval, threshold list retrieval, session retrieval, session list retrieval, artifact persistence, lineage persistence, orchestrator list surfaces, and Herald list surfaces.
