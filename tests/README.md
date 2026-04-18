# Tests

This directory holds integration and verification checks for the Eidonic Core build.

## Current integration test
- `integration/test_full_chain.ps1`

## Purpose
This test sends one request to `signal-gateway` and verifies the full nested downstream response from:
- `herald-service`
- `session-engine`
- `eidon-orchestrator`

It also verifies that:
- the started session can be retrieved from `session-engine` persistence
- the orchestration artifact can be retrieved from `eidon-orchestrator` persistence

## Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\tests\integration\test_full_chain.ps1
```

## Expected condition
The current Phase 2 services must already be running locally on:
- port 8000 for `signal-gateway`
- port 8001 for `session-engine`
- port 8002 for `herald-service`
- port 8003 for `eidon-orchestrator`

## Verified outcomes
- full chained gateway response
- nested Herald result
- nested Session result
- nested Eidon result
- persisted session lookup from `session-engine`
- persisted artifact lookup from `eidon-orchestrator`
