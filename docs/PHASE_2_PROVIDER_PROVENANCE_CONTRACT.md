# Phase 2 Provider Provenance Contract

This document records the addition of provider provenance to persisted Orchestrator artifact and lineage contracts.

## Purpose
Make generated artifacts and lineage traceable to the provider backend and model that produced them.

## Why this matters
- storage provenance alone is not enough once real model adapters exist
- future comparisons between stub, Ollama, model sizes, and later adapters require persisted generation provenance
- traceability should be added before routing or training complexity appears

## Current provenance fields
Artifact records:
- `provider_backend`
- `provider_model`

Lineage records:
- `artifact_provider_backend`
- `artifact_provider_model`

## Current truth
This branch adds provider provenance to contracts, persistence, and retrieval surfaces. It does not add routing or training.
