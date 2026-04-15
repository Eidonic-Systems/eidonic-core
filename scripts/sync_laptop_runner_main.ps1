param(
    [string]$RepoRoot = ".",
    [switch]$RunGate
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

    if ($LASTEXITCODE -ne 0) {
        throw ("Step failed: {0} (exit code {1})." -f $Label, $LASTEXITCODE)
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
Set-Location $resolvedRepoRoot

Run-Step -Label "Fetching origin" -Action {
    git fetch origin --prune
}

Run-Step -Label "Switching to main" -Action {
    git switch main
}

Run-Step -Label "Pulling main" -Action {
    git pull --ff-only
}

Run-Step -Label "Bootstrapping service venvs" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_phase2_service_venvs.ps1 -RepoRoot $resolvedRepoRoot
}

Run-Step -Label "Bootstrapping PostgreSQL" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_phase2_postgres.ps1 -RepoRoot $resolvedRepoRoot
}

Run-Step -Label "Checking host bootstrap" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\check_phase2_host_bootstrap.ps1 -RepoRoot $resolvedRepoRoot -CheckRunnerFolder
}

if ($RunGate) {
    Run-Step -Label "Running Phase 2 gate" -Action {
        powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1
    }
}

Write-Host ""
Write-Host "Laptop runner main sync passed." -ForegroundColor Green
