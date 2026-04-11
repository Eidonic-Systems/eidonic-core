# Phase 2 Integration Test Provider Warmup Failure Surface

This document records the addition of a focused integration test for the controlled provider-warmup failure path in Orchestrator.

## Purpose
Prove that the explicit warmup surface fails clearly and truthfully when the configured provider model is missing.

## Current endpoint under test
- `POST /provider/warm` under a controlled missing-model override

## Failure truth under test
- `status = warm_failed`
- `provider.ready = false`
- `provider_error_code = provider_model_missing`
- `provider_error_message` names the missing model

## Why this matters
- startup now depends on warmup
- warmup success alone is not enough
- a hardened startup sequence needs a durable proof that warmup fails clearly when the provider is misconfigured

## Current truth
The focused provider-warmup failure integration test proves that a controlled missing-model condition returns structured warm failure truth.
