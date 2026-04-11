# Phase 2 Integration Test Provider Warmup Surface

This document records the addition of a focused integration test for the Orchestrator provider warmup and readiness surface.

## Purpose
Prove that provider readiness moves from false to true through the explicit warmup surface.

## Current endpoints under test
- `GET /health` before warmup
- `POST /provider/warm`
- `GET /health` after warmup

## Readiness truth under test
- pre-warm `provider.ready = false`
- warm response `status = warmed`
- warm response `provider.ready = true`
- post-warm `provider.ready = true`

## Why this matters
- timeout hardening is weaker than explicit readiness proof
- warm state should be proven automatically, not assumed
- this keeps the warmup surface honest before more provider complexity is added

## Current truth
The focused provider warmup integration test proves the Orchestrator warmup surface and readiness transition directly.
