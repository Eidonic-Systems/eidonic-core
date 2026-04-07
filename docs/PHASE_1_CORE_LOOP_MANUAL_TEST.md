# Phase 1 Core Loop Manual Test

This document records the first manual end-to-end test path for the Phase 1 service spine.

## Services and ports
- `signal-gateway` → `http://127.0.0.1:8000`
- `herald-service` → `http://127.0.0.1:8001`
- `session-engine` → `http://127.0.0.1:8002`
- `eidon-orchestrator` → `http://127.0.0.1:8003`

## Purpose
Prove that the first four service shells can each run locally and accept valid manual input.

## Step 1: signal-gateway
Open:
`http://127.0.0.1:8000/docs`

Test:
- `POST /signals/ingest`

Use:
`services/signal-gateway/examples/sample_signal_event.json`

Expected response:
- `status` = `accepted`
- `service` = `signal-gateway`
- `received_signal_id` = `sig-001`

## Step 2: herald-service
Open:
`http://127.0.0.1:8001/docs`

Test:
- `POST /threshold/check`

Use:
`services/herald-service/examples/sample_threshold_check.json`

Expected response:
- `status` = `reviewed`
- `service` = `herald-service`
- `signal_id` = `sig-001`
- `threshold_result` = `pass`

## Step 3: session-engine
Open:
`http://127.0.0.1:8002/docs`

Test:
- `POST /sessions/start`

Use:
`services/session-engine/examples/sample_session_start.json`

Expected response:
- `status` = `started`
- `service` = `session-engine`
- `session_id` = `session-sig-001`
- `signal_id` = `sig-001`

## Step 4: eidon-orchestrator
Open:
`http://127.0.0.1:8003/docs`

Test:
- `POST /orchestrate`

Use:
`services/eidon-orchestrator/examples/sample_orchestration_request.json`

Expected response:
- `status` = `orchestrated`
- `service` = `eidon-orchestrator`
- `session_id` = `session-sig-001`
- `signal_id` = `sig-001`

## Current truth
This is not yet a networked service chain.
These services are still being tested manually as separate shells using aligned payloads.

## Next build direction
The next practical step after this manual pack is wiring the first real chain between services or introducing shared schemas into service code.
