# Phase 2 Integration Test List Limit Surfaces

This document records the extension of the full integration test to verify list limit behavior across the current Phase 2 services.

## Purpose
Move list limit verification into the standard Phase 2 integration proof.

## Current endpoints under test
- `GET /signals?limit=1`
- `GET /thresholds?limit=1`
- `GET /sessions?limit=1`
- `GET /artifacts?limit=1`
- `GET /lineage?limit=1`

## Why this matters
- mature store contracts should prove limit semantics, not only collection existence
- this keeps list surfaces honest after contract hardening
- the integration test should reflect the current contract behavior, not only the current route presence

## Current truth
The test now verifies list limit behavior across signal, threshold, session, artifact, and lineage surfaces.
