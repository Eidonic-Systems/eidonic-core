$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Start-ServiceWindow {
    param(
        [string]$Name,
        [string]$WorkingDirectory,
        [string]$Command,
        [int]$Port
    )

    $scriptBlock = @"
Set-Location '$WorkingDirectory'
Write-Host 'Starting $Name on port $Port' -ForegroundColor Cyan
$Command
"@

    Start-Process powershell -ArgumentList @(
        '-NoExit',
        '-ExecutionPolicy', 'Bypass',
        '-Command', $scriptBlock
    ) | Out-Null

    Write-Host "Started $Name on port $Port" -ForegroundColor Green
}

function Wait-For-Health {
    param(
        [string]$Name,
        [string]$Url,
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
            if ($null -ne $response.status -and $response.status -eq 'ok') {
                Write-Host "$Name health is ready." -ForegroundColor Green
                return
            }
        }
        catch {
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "$Name health did not become ready at $Url."
}

Write-Host ""
Write-Host "Starting Phase 2 local stack..." -ForegroundColor Yellow
Write-Host ""

Start-ServiceWindow `
    -Name 'herald-service' `
    -WorkingDirectory (Join-Path $RepoRoot 'services\herald-service') `
    -Command '.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001 --reload' `
    -Port 8001

Start-ServiceWindow `
    -Name 'session-engine' `
    -WorkingDirectory (Join-Path $RepoRoot 'services\session-engine') `
    -Command '.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8002 --reload' `
    -Port 8002

Start-ServiceWindow `
    -Name 'eidon-orchestrator' `
    -WorkingDirectory (Join-Path $RepoRoot 'services\eidon-orchestrator') `
    -Command '.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8003 --reload' `
    -Port 8003

Start-ServiceWindow `
    -Name 'signal-gateway' `
    -WorkingDirectory (Join-Path $RepoRoot 'services\signal-gateway') `
    -Command '.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload' `
    -Port 8000

Write-Host ""
Write-Host "Waiting for service health..." -ForegroundColor Yellow

Wait-For-Health -Name 'herald-service' -Url 'http://127.0.0.1:8001/health'
Wait-For-Health -Name 'session-engine' -Url 'http://127.0.0.1:8002/health'
Wait-For-Health -Name 'eidon-orchestrator' -Url 'http://127.0.0.1:8003/health'
Wait-For-Health -Name 'signal-gateway' -Url 'http://127.0.0.1:8000/health'

Write-Host ""
Write-Host "Warming Eidon provider..." -ForegroundColor Yellow

try {
    powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\warm_eidon_provider.ps1')
    Write-Host "Eidon provider warmup completed during stack startup." -ForegroundColor Green
}
catch {
    Write-Error "Eidon provider warmup failed during stack startup. Stop and inspect the provider before continuing."
    throw
}

Write-Host ""
Write-Host "Phase 2 local stack launcher started four PowerShell windows and completed provider warmup." -ForegroundColor Green
