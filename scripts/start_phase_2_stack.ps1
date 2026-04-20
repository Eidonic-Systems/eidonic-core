$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ResolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$TopologyManifestPath = Join-Path $ResolvedRepoRoot 'config\service_topology_manifest.json'

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

function Get-TopologyServices {
    param(
        [string]$ManifestPath
    )

    if (-not (Test-Path $ManifestPath)) {
        throw "Missing service topology manifest at $ManifestPath"
    }

    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $services = @($manifest.services)

    if ($services.Count -eq 0) {
        throw "Service topology manifest did not declare any services."
    }

    foreach ($service in $services) {
        foreach ($requiredProperty in @('name', 'port', 'health_url', 'startup_workdir', 'startup_command')) {
            $value = [string]$service.$requiredProperty
            if ([string]::IsNullOrWhiteSpace($value)) {
                throw "Service topology manifest entry for '$($service.name)' is missing required property '$requiredProperty'."
            }
        }
    }

    return $services
}

$services = Get-TopologyServices -ManifestPath $TopologyManifestPath

Write-Host ""
Write-Host "Running Phase 2 topology consistency validation..." -ForegroundColor Yellow

& powershell -ExecutionPolicy Bypass -File (Join-Path $ResolvedRepoRoot 'scripts\validate_phase2_topology_consistency.ps1') -RepoRoot $ResolvedRepoRoot
if ($LASTEXITCODE -ne 0) {
    throw "Phase 2 topology consistency validation failed. Stop and fix topology drift before starting the stack."
}

Write-Host ""
Write-Host "Running Phase 2 startup preflight..." -ForegroundColor Yellow

& powershell -ExecutionPolicy Bypass -File (Join-Path $ResolvedRepoRoot 'scripts\check_phase_2_runtime_prereqs.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Phase 2 runtime preflight failed. Stop and fix the environment before starting the stack."
}

Write-Host ""
Write-Host "Running Phase 2 PostgreSQL bootstrap..." -ForegroundColor Yellow

& powershell -ExecutionPolicy Bypass -File (Join-Path $ResolvedRepoRoot 'scripts\bootstrap_phase2_postgres.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Phase 2 PostgreSQL bootstrap failed. Stop and fix the database before starting the stack."
}

Write-Host ""
Write-Host "Running Phase 2 PostgreSQL schema bootstrap..." -ForegroundColor Yellow

& powershell -ExecutionPolicy Bypass -File (Join-Path $ResolvedRepoRoot 'scripts\bootstrap_phase2_postgres_schema.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Phase 2 PostgreSQL schema bootstrap failed. Stop and fix the schema before starting the stack."
}

Write-Host ""
Write-Host "Running Phase 2 PostgreSQL schema drift validation..." -ForegroundColor Yellow

& powershell -ExecutionPolicy Bypass -File (Join-Path $ResolvedRepoRoot 'scripts\validate_phase2_postgres_schema_drift.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Phase 2 PostgreSQL schema drift validation failed. Stop and fix the schema before starting the stack."
}

Write-Host ""
Write-Host "Starting Phase 2 local stack from topology manifest..." -ForegroundColor Yellow
Write-Host ""

foreach ($service in $services) {
    $serviceName = if ([string]::IsNullOrWhiteSpace([string]$service.startup_name)) { [string]$service.name } else { [string]$service.startup_name }
    $workingDirectory = Join-Path $ResolvedRepoRoot ([string]$service.startup_workdir)

    if (-not (Test-Path $workingDirectory)) {
        throw "Startup working directory for '$serviceName' does not exist: $workingDirectory"
    }

    Start-ServiceWindow `
        -Name $serviceName `
        -WorkingDirectory $workingDirectory `
        -Command ([string]$service.startup_command) `
        -Port ([int]$service.port)
}

Write-Host ""
Write-Host "Waiting for service health..." -ForegroundColor Yellow

foreach ($service in $services) {
    $serviceName = if ([string]::IsNullOrWhiteSpace([string]$service.startup_name)) { [string]$service.name } else { [string]$service.startup_name }
    Wait-For-Health -Name $serviceName -Url ([string]$service.health_url)
}

Write-Host ""
Write-Host "Warming Eidon provider..." -ForegroundColor Yellow

& powershell -ExecutionPolicy Bypass -File (Join-Path $ResolvedRepoRoot 'scripts\warm_eidon_provider.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Eidon provider warmup failed during stack startup. Stop and inspect the provider before continuing."
}

Write-Host ""
Write-Host "Phase 2 startup sequence completed: topology validated, preflight passed, services started, health checks passed, provider warmed." -ForegroundColor Green

