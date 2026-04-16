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

function Start-ServiceFromTopology {
    param(
        [string]$ResolvedRepoRoot,
        $Service
    )

    $startupName = [string]$Service.startup_name
    $startupWorkdir = [string]$Service.startup_workdir
    $startupCommand = [string]$Service.startup_command

    if ([string]::IsNullOrWhiteSpace($startupName)) {
        throw "Service topology entry is missing startup_name."
    }

    if ([string]::IsNullOrWhiteSpace($startupWorkdir)) {
        throw "Service '$startupName' is missing startup_workdir."
    }

    if ([string]::IsNullOrWhiteSpace($startupCommand)) {
        throw "Service '$startupName' is missing startup_command."
    }

    $workdirPath = Join-Path $ResolvedRepoRoot $startupWorkdir
    if (-not (Test-Path $workdirPath)) {
        throw "Startup workdir for '$startupName' does not exist: $workdirPath"
    }

    Write-Host ("Starting {0}..." -f $startupName) -ForegroundColor Yellow

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "Set-Location '$workdirPath'; $startupCommand"
    ) | Out-Null
}

$serviceTopology = Get-ServiceTopology -ResolvedRepoRoot $RepoRoot