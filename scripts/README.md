# Scripts

This directory holds local helper scripts for running and testing the Eidonic Core build.

## start_phase_2_stack.ps1

Starts four new PowerShell windows for the current local Phase 2 stack:
- `herald-service` on port 8001
- `session-engine` on port 8002
- `eidon-orchestrator` on port 8003
- `signal-gateway` on port 8000

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1
```

## test_phase_1_core_loop.ps1

Runs the earlier Phase 1 core loop checks against locally running services.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test_phase_1_core_loop.ps1
```
