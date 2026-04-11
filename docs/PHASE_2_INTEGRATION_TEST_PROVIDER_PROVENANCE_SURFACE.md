# Phase 2 Integration Test Provider Provenance Surface

This document records the extension of the full integration test to verify persisted provider provenance in Orchestrator artifact and lineage retrieval.

## Purpose
Move provider-provenance verification into the standard Phase 2 integration proof.

## Current retrieval surfaces under test
- `GET /artifacts/{artifact_id}`
- `GET /lineage/{artifact_id}`

## Provenance fields under test
- artifact: `provider_backend`
- artifact: `provider_model`
- lineage: `artifact_provider_backend`
- lineage: `artifact_provider_model`

## Why this matters
- persisted generation provenance should be proven automatically, not trusted implicitly
- future provider and model comparisons depend on these fields being stable and truthful
- traceability is part of the current live Orchestrator surface now

## Current truth
The standard proof now verifies provider provenance in persisted artifact and lineage retrieval.
