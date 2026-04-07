# Eidon Orchestrator

The Eidon Orchestrator is the first orchestration service for Eidonic Core.

## Responsibility
- receive thresholded and session-bound input
- perform the first orchestration pass
- return a basic orchestration result
- later hold routing, tool use, memory access, and multi-organ weaving logic

## Current phase
Phase 1 scaffold only

## Current endpoints
- `GET /health`
- `POST /orchestrate`

## Notes
This service currently accepts and echoes valid orchestration input.
Routing, memory access, tool invocation, council logic, and response shaping are not implemented yet.
