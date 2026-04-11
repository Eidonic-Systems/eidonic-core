# Phase 2 Provider Cold Start Timeout Hardening

This document records the hardening of Signal Gateway timeout behavior for local-model cold starts.

## Purpose
Keep upstream timeouts realistic when Orchestrator uses a local model that may need extra time on the first run.

## What changed
- Signal Gateway now uses explicit per-downstream timeout settings
- Herald and Session Engine stay on tight defaults
- Orchestrator gets a longer default timeout for local-model cold starts

## Why this matters
- a local model can be healthy and still be slow on the first call
- the chain should not fail prematurely because one upstream timeout is too optimistic
- this hardens runtime discipline without changing the provider contract or adding routing complexity
