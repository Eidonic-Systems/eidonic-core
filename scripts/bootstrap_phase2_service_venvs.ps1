param(
    [string]$RepoRoot = ".",
    [string[]]$Services = @(
        "eidon-orchestrator",
        "signal-gateway",
        "session-engine",
        "herald-service"
    )
)

$ErrorActionPreference = "Stop"

function Add-Result {
    param(
        [System.Collections.ArrayList]$Results,
        [string]$Service,
        [string]$Status,
        [string]$Detail
    )

    [void]$Results.Add([pscustomobject]@{
        service = $Service
        status = $Status
        detail = $Detail
    })
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $pythonCmd) {
    throw "python not found on PATH."
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$results = [System.Collections.ArrayList]::new()

foreach ($service in $Services) {
    $serviceRoot = Join-Path $resolvedRepoRoot ("services\{0}" -f $service)

    if (-not (Test-Path $serviceRoot)) {
        Add-Result -Results $results -Service $service -Status "missing_service_folder" -Detail $serviceRoot
        continue
    }

    $venvPath = Join-Path $serviceRoot ".venv"
    $venvPython = Join-Path $venvPath "Scripts\python.exe"
    $requirementsPath = Join-Path $serviceRoot "requirements.txt"

    $createdVenv = $false

    if (-not (Test-Path $venvPython)) {
        Write-Host ""
        Write-Host ("Creating venv for {0}..." -f $service) -ForegroundColor Yellow
        & python -m venv $venvPath
        if ($LASTEXITCODE -ne 0) {
            throw ("Failed to create venv for {0}." -f $service)
        }
        $createdVenv = $true
    }

    if (-not (Test-Path $venvPython)) {
        throw ("Missing venv python after creation for {0}: {1}" -f $service, $venvPython)
    }

    Write-Host ""
    Write-Host ("Upgrading pip for {0}..." -f $service) -ForegroundColor Yellow
    & $venvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to upgrade pip for {0}." -f $service)
    }

    if (-not (Test-Path $requirementsPath)) {
        Add-Result -Results $results -Service $service -Status "missing_requirements" -Detail $requirementsPath
        continue
    }

    Write-Host ""
    Write-Host ("Installing requirements for {0}..." -f $service) -ForegroundColor Yellow
    Push-Location $serviceRoot
    try {
        & $venvPython -m pip install -r .\requirements.txt
        if ($LASTEXITCODE -ne 0) {
            throw ("Failed to install requirements for {0}." -f $service)
        }
    }
    finally {
        Pop-Location
    }

    Add-Result -Results $results -Service $service -Status ($(if ($createdVenv) { "bootstrapped" } else { "refreshed" })) -Detail $venvPython
}

$missing = @($results | Where-Object { $_.status -eq "missing_service_folder" -or $_.status -eq "missing_requirements" })

$summary = [ordered]@{
    status = $(if ($missing.Count -eq 0) { "passed" } else { "failed" })
    repo_root = $resolvedRepoRoot
    total_services = $Services.Count
    failed_services = $missing.Count
    results = $results
}

Write-Host ""
Write-Host "Phase 2 service venv bootstrap summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Phase 2 service venv bootstrap failed."
}

Write-Host ""
Write-Host "Phase 2 service venv bootstrap passed." -ForegroundColor Green
