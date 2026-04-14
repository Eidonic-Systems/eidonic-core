param(
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

Run-Step -Label "Comparing governance manifest to baseline" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\compare_governance_manifest_to_baseline.ps1
}

Run-Step -Label "Validating governance manifest change discipline" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\validate_governance_manifest_change.ps1
}

Run-Step -Label "Running governance eval surface" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\run_governance_eval.ps1
}

Run-Step -Label "Comparing governance eval to baseline" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\compare_governance_eval_to_baseline.ps1
}

Run-Step -Label "Running governance rule provenance integration test" -Action {
    powershell -ExecutionPolicy Bypass -File .\tests\integration\test_governance_rule_provenance_surface.ps1
}

Run-Step -Label "Running full-chain integration test" -Action {
    powershell -ExecutionPolicy Bypass -File .\tests\integration\test_full_chain.ps1
}

Write-Host ""
Write-Host "Governance gate surface passed." -ForegroundColor Green
