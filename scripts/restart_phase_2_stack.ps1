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

function Get-ServiceTopology {
    param([string]$ResolvedRepoRoot)

    $manifestPath = Join-Path $ResolvedRepoRoot "config\service_topology_manifest.json"
    if (-not (Test-Path $manifestPath)) {
        throw "Missing service topology manifest at $manifestPath"
    }

    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    if ($null -eq $manifest.services -or $manifest.services.Count -eq 0) {
        throw "Service topology manifest has no services."
    }

    return $manifest
}

function Stop-Phase2ServiceProcesses {
    param($Services)

    $patterns = @()
    foreach ($service in $Services) {
        foreach ($pattern in $service.process_match_patterns) {
            if (-not [string]::IsNullOrWhiteSpace([string]$pattern)) {
                $patterns += [string]$pattern
            }
        }
    }

    if ($patterns.Count -eq 0) {
        Write-Host "No process match patterns declared in service topology manifest." -ForegroundColor DarkGray
        return
    }

    $candidates = Get-CimInstance Win32_Process | Where-Object {
        $cmd = $_.CommandLine
        if ($null -eq $cmd) { return $false }

        foreach ($pattern in $patterns) {
            if ($cmd -like "*$pattern*") {
                return $true
            }
        }

        return $false
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
    param($Services)

    $ports = @($Services | ForEach-Object { [int]$_.port } | Sort-Object -Unique)

    foreach ($port in $ports) {
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
$manifest = Get-ServiceTopology -ResolvedRepoRoot $resolvedRepoRoot

Run-Step -Label "Stopping Phase 2 service processes" -Action {
    Stop-Phase2ServiceProcesses -Services $manifest.services
}

Run-Step -Label "Clearing known Phase 2 ports" -Action {
    Stop-PortListeners -Services $manifest.services
}

Run-Step -Label "Starting Phase 2 stack" -Action {
    powershell -ExecutionPolicy Bypass -File .\scripts\start_phase_2_stack.ps1
}

if ($RunGate) {
    Run-Step -Label "Running Phase 2 gate" -Action {
        powershell -ExecutionPolicy Bypass -File .\scripts\run_phase2_gate.ps1 -SkipStackStart
    }
}

Write-Host ""
Write-Host "Phase 2 stack restart passed." -ForegroundColor Green
