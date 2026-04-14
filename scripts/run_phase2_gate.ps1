param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [switch]$SkipStackStart
)

$ErrorActionPreference = "Stop"

function Run-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host ("==> {0}" -f $Label) -ForegroundColor Yellow
    & $Action
}

if (-not $SkipStackStart) {
    Run-Step -Label "Starting standard Phase 2 stack" -Action {
        powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1
    }
}

Run-Step -Label "Warming provider" -Action {
    Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" -Method Post | ConvertTo-Json -Depth 12
}

Run-Step -Label "Checking Phase 2 health" -Action {
    $health = Invoke-RestMethod -Uri "$EidonBaseUrl/health" -Method Get

    if ($health.status -ne "ok") {
        throw "Phase 2 health failed: service status is not ok."
    }

    if ($health.artifact_store.status -ne "ok") {
        throw "Phase 2 health failed: artifact store status is not ok."
    }

    if ($health.lineage_store.status -ne "ok") {
        throw "Phase 2 health failed: lineage store status is not ok."
    }

    if ($health.provider.status -ne "ok") {
        throw "Phase 2 health failed: provider status is not ok."
    }

    if (-not $health.provider.ready) {
        throw "Phase 2 health failed: provider is not ready."
    }

    $health | ConvertTo-Json -Depth 12
}

Run-Step -Label "Running governance gate" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\run_governance_gate.ps1 -SkipStackStart
}

Write-Host ""
Write-Host "Phase 2 gate surface passed." -ForegroundColor Green
