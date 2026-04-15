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

    $global:LASTEXITCODE = 0
    & $Action

    $exitCode = $LASTEXITCODE
    if ($null -ne $exitCode -and $exitCode -ne 0) {
        throw ("Step failed: {0} (exit code {1})." -f $Label, $exitCode)
    }
}

function Stop-Phase2ServiceProcesses {
    param([string]$ResolvedRepoRoot)

    $patterns = @(
        "services\signal-gateway",
        "services\session-engine",
        "services\herald-service",
        "services\eidon-orchestrator",
        "app.main:app"
    )

    $candidates = Get-CimInstance Win32_Process | Where-Object {
        $null -ne $_.CommandLine -and (
            ($patterns | Where-Object { $_ -and $_ -in $_.CommandLine }).Count -gt 0
        )
    }

    $pids = @($candidates |
        Where-Object { $_.ProcessId -ne $PID } |
        Select-Object -ExpandProperty ProcessId -Unique)

    if ($pids.Count -eq 0) {
        Write-Host "No Phase 2 service processes matched by command line." -ForegroundColor DarkGray
        return
    }

    foreach ($processId in $pids) {
        Write-Host ("Stopping process {0}..." -f $processId) -ForegroundColor Yellow
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 2
}

function Stop-PortListeners {
    param([int[]]$Ports)

    foreach ($port in $Ports) {
        $connections = @(Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique)

        if ($connections.Count -eq 0) {
            Write-Host ("No listeners found on port {0}." -f $port) -ForegroundColor DarkGray
            continue
        }

        foreach ($processId in $connections) {
            if ($processId -eq $PID) { continue }
            Write-Host ("Stopping port holder {0} on port {1}..." -f $processId, $port) -ForegroundColor Yellow
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
        }
    }

    Start-Sleep -Seconds 2
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
Set-Location $resolvedRepoRoot

Run-Step -Label "Stopping Phase 2 service processes" -Action {
    Stop-Phase2ServiceProcesses -ResolvedRepoRoot $resolvedRepoRoot
}

Run-Step -Label "Clearing known Phase 2 ports" -Action {
    Stop-PortListeners -Ports @(8000, 8001, 8002, 8003)
}

Run-Step -Label "Starting Phase 2 stack" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1
}

if ($RunGate) {
    Run-Step -Label "Running Phase 2 gate" -Action {
        powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1
    }
}

Write-Host ""
Write-Host "Phase 2 stack restart passed." -ForegroundColor Green
