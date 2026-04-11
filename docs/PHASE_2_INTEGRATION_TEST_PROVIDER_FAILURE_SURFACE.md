# Phase 2 Integration Test Provider Failure Surface

This document records the addition of a focused integration test for the controlled provider-failure path in Orchestrator.

## Purpose
Prove the provider failure surface without bloating the normal happy-path chain test.

## Current endpoint under test
- `POST /orchestrate` with a controlled missing-model condition
- `GET /artifacts/{artifact_id}`
- `GET /lineage/{artifact_id}`

## Failure truth under test
- response status `provider_failed`
- `provider_error_code = provider_model_missing`
- artifact provider failure fields persisted
- lineage provider failure fields persisted

## Why this matters
- failure semantics should be proven automatically, not only exercised manually
- happy-path proof and failure-path proof should remain separate and readable
- this keeps the provider seam honest before more model complexity is added

## Current truth
The focused provider-failure integration test proves that a controlled missing-model scenario is persisted and retrievable as structured failure truth.
