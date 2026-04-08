# Phase 2 Full Chain

This document records the first full HTTP chained spine of the Eidonic Core scaffold.

## Chain
`signal-gateway` → `herald-service` → `session-engine` → `eidon-orchestrator`

## Purpose
Prove that a single ingest request can move through the current downstream service chain and return all nested results in one response.

## Local service ports
- `signal-gateway` → `http://127.0.0.1:8000`
- `herald-service` → `http://127.0.0.1:8001`
- `session-engine` → `http://127.0.0.1:8002`
- `eidon-orchestrator` → `http://127.0.0.1:8003`

## Manual terminal test
From `services/signal-gateway`:

```powershell
$body = Get-Content .\examples\sample_signal_event.json -Raw
Invoke-RestMethod -Uri "http://127.0.0.1:8000/signals/ingest" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body | ConvertTo-Json -Depth 12
```

## Expected result
The response should include:
- top-level gateway acceptance
- nested `herald_result`
- nested `session_result`
- nested `eidon_result`

## Current truth
This is still a direct HTTP scaffold chain.
There is no queue, no event bus, no retry policy, and no durable session persistence yet.
