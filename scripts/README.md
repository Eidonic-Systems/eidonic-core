# Scripts

This directory holds local helper scripts for running and testing the Eidonic Core build.

## test_phase_1_core_loop.ps1

Runs the Phase 1 core loop checks against locally running services.

### Current scope
- reads example payloads from each service directory
- sends requests to the local service endpoints
- validates the expected response fields
- fails loudly if a response is wrong or a payload file is missing

### Services expected to be running
- signal-gateway on port 8000
- herald-service on port 8001
- session-engine on port 8002
- eidon-orchestrator on port 8003

### Run from repository root
`powershell -ExecutionPolicy Bypass -File .\scripts\test_phase_1_core_loop.ps1`
