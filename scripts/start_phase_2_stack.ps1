param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$services = @(
    @{ Name = "herald-service"; Port = 8001 },
    @{ Name = "session-engine"; Port = 8002 },
    @{ Name = "eidon-orchestrator"; Port = 8003 },
    @{ Name = "signal-gateway"; Port = 8000 }
)

foreach ($service in $services) {
    $servicePath = Join-Path $RepoRoot "services\$($service.Name)"
    $pythonPath = Join-Path $servicePath ".venv\Scripts\python.exe"

    if (-not (Test-Path $pythonPath)) {
        throw "Missing service venv Python: $pythonPath"
    }

    $command = "Set-Location '$servicePath'; & '$pythonPath' -m uvicorn app.main:app --reload --port $($service.Port)"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $command | Out-Null
    Write-Host "Started $($service.Name) on port $($service.Port)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Phase 2 local stack launcher started four PowerShell windows." -ForegroundColor Green
