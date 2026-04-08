# Phase 2 Gateway to Herald Chain

This document records the first real service-to-service handoff in the Eidonic Core build.

## Purpose
Move from parallel shell testing to the first live downstream call:
`signal-gateway` -> `herald-service`

## Services involved
- `signal-gateway` on `http://127.0.0.1:8000`
- `herald-service` on `http://127.0.0.1:8001`

## Current behavior
When `signal-gateway` receives a valid `SignalEvent`, it now:
1. accepts the ingress payload
2. constructs the threshold payload for Herald
3. posts that payload to `herald-service`
4. returns the Herald result inside the gateway response

## Manual test
1. Start `herald-service` on port `8001`
2. Start `signal-gateway` on port `8000`
3. Open:
   `http://127.0.0.1:8000/docs`
4. Run:
   `POST /signals/ingest`
5. Use:
   `services/signal-gateway/examples/sample_signal_event.json`

## Expected response
The response should include:
- `status` = `accepted`
- `service` = `signal-gateway`
- `received_signal_id` = `sig-001`
- `herald_result.service` = `herald-service`
- `herald_result.threshold_result` = `pass`

## Current truth
This is the first live downstream handoff only.
The session engine and Eidon orchestrator are still being tested as separate shells.
