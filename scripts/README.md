# Scripts

This directory holds local helper scripts for running and testing the Eidonic Core build.

## validate_service_topology_manifest.ps1

Validates the structure and runtime viability of `config/service_topology_manifest.json`.

Checks include:
- required manifest fields
- duplicate service names
- duplicate ports
- health URL and port alignment
- startup command and port alignment
- required service paths exist

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_service_topology_manifest.ps1
```

## validate_phase2_dependency_pins.ps1

Validates the bounded dependency reproducibility posture for the current Phase 2 Python services.

Dependency truth source:
- `config/phase2_python_dependency_truth.json`

Checks include:
- exact direct `==` pins in each Phase 2 service `requirements.txt`
- exactly one editable local `common-schemas` reference per service
- expected shared dependency pins in `packages/common-schemas/python/pyproject.toml`

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_dependency_pins.ps1
```

## start_phase_2_stack.ps1

Starts four new PowerShell windows for the current local Phase 2 stack using `config/service_topology_manifest.json` as the topology truth source.

Current manifest-backed ports:
- `signal-gateway` on port 8000
- `session-engine` on port 8001
- `herald-service` on port 8002
- `eidon-orchestrator` on port 8003

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1
```

## validate_phase2_topology_consistency.ps1

Validates that the current topology truth surfaces stay aligned:
- `config/service_topology_manifest.json`
- `.env.example`
- `tests/README.md`
- `scripts/start_phase_2_stack.ps1`
- `scripts/README.md`
- `services/signal-gateway/app/main.py`
- `tests/integration/test_full_chain.ps1`

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate_phase2_topology_consistency.ps1
```

## run_phase2_gate.ps1

Runs the current Phase 2 gate surface, including dependency pin validation, service topology manifest validation, and topology consistency validation before the rest of the gate flow.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1
```

## pin_phase2_python_dependencies.ps1

Pins still-floating direct Python service dependencies to exact versions using the current local service virtual environments as the source of truth.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pin_phase2_python_dependencies.ps1
```

## test_phase_1_core_loop.ps1

Runs the earlier Phase 1 core loop checks against locally running services.

### Run from repository root
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test_phase_1_core_loop.ps1
```
