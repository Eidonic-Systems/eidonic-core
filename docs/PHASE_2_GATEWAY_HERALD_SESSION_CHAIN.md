# Phase 2 Gateway to Herald to Session Chain

This document records the first three-step HTTP service chain in the Eidonic Core spine.

## Chain
`signal-gateway` → `herald-service` → `session-engine`

## Purpose
Turn the current scaffold from isolated service shells into a real downstream pathway.

## Services and ports
- `signal-gateway` → `http://127.0.0.1:8000`
- `herald-service` → `http://127.0.0.1:8001`
- `session-engine` → `http://127.0.0.1:8002`

## Test path
1. Start `herald-service`
2. Start `session-engine`
3. Start `signal-gateway`
4. Send the sample signal payload to:
   - `POST http://127.0.0.1:8000/signals/ingest`

## Expected response shape
The gateway response should contain:
- `status` = `accepted`
- `service` = `signal-gateway`
- `received_signal_id` = `sig-001`
- `herald_result`
- `session_result`

## Current truth
- Herald is still a simple pass-through threshold shell
- Session Engine is still a simple session-start shell
- Signal Gateway now performs the first real two-hop handoff
- Eidon Orchestrator is not yet chained into this path

## Next build direction
The next honest extension is:
`signal-gateway` → `herald-service` → `session-engine` → `eidon-orchestrator`
