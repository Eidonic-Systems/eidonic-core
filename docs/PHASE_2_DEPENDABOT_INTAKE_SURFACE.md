# Phase 2 Dependabot Intake Surface

This document records the first bounded intake pass for newly opened Dependabot update branches.

## Purpose
Separate update visibility from update adoption.

## Observed Dependabot update branches
Current visible update pressure includes:
- `dependabot/github_actions/actions/checkout-6.0.2`
- `dependabot/pip/services/eidon-orchestrator/fastapi-0.136.0`
- `dependabot/pip/services/eidon-orchestrator/httpx-0.28.1`
- `dependabot/pip/services/eidon-orchestrator/pydantic-2.13.2`
- `dependabot/pip/services/eidon-orchestrator/uvicorn-0.44.0`
- `dependabot/pip/services/herald-service/fastapi-0.136.0`
- `dependabot/pip/services/herald-service/pydantic-2.13.2`
- `dependabot/pip/services/herald-service/uvicorn-0.44.0`
- `dependabot/pip/services/session-engine/fastapi-0.136.0`
- `dependabot/pip/services/session-engine/pydantic-2.13.2`
- `dependabot/pip/services/session-engine/uvicorn-0.44.0`
- `dependabot/pip/services/signal-gateway/fastapi-0.136.0`
- `dependabot/pip/services/signal-gateway/httpx-0.28.1`
- `dependabot/pip/services/signal-gateway/pydantic-2.13.2`
- `dependabot/pip/services/signal-gateway/uvicorn-0.44.0`

## Intake classification
Current decision:
- do not blind-merge any of these updates
- treat all currently visible updates as compatibility-sensitive
- defer adoption to dedicated upgrade branches with explicit proof passes

## Why these are deferred
These updates touch:
- web framework behavior
- validation model behavior
- ASGI server behavior
- HTTP client behavior
- workflow action runtime behavior

That means they can affect:
- service startup
- request handling
- provider calls
- proof scripts
- CI execution behavior

## Current truth
This branch is intake only.

It does not adopt the updates.
It records what is visible now and keeps upgrade work out of unrelated branches.
