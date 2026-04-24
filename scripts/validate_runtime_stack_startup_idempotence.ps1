param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Add-Failure {
    param(
        [System.Collections.ArrayList]$Failures,
        [string]$Message
    )

    [void]$Failures.Add($Message)
}

function Invoke-CapturedPowerShellFile {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @()
    )

    $output = (& powershell -ExecutionPolicy Bypass -File $FilePath @Arguments 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE

    return [pscustomobject]@{
        exit_code = $exitCode
        output = $output.TrimEnd()
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$startScriptPath = Join-Path $resolvedRepoRoot 'scripts\start_phase_2_stack.ps1'
$topologyManifestPath = Join-Path $resolvedRepoRoot 'config\service_topology_manifest.json'

if (-not (Test-Path $startScriptPath)) {
    throw "Missing startup script at $startScriptPath"
}

if (-not (Test-Path $topologyManifestPath)) {
    throw "Missing topology manifest at $topologyManifestPath"
}

$manifest = Get-Content $topologyManifestPath -Raw | ConvertFrom-Json
$services = @($manifest.services)

if ($services.Count -eq 0) {
    throw "Service topology manifest did not declare any services."
}

Write-Host ""
Write-Host "Runtime stack startup idempotence validation:" -ForegroundColor Yellow
Write-Host ("  repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("  startup script: {0}" -f $startScriptPath)

$firstRun = Invoke-CapturedPowerShellFile -FilePath $startScriptPath
$secondRun = Invoke-CapturedPowerShellFile -FilePath $startScriptPath

$failures = [System.Collections.ArrayList]::new()

if ($firstRun.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message ("first startup run failed with exit code {0}" -f $firstRun.exit_code)
}

if ($secondRun.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message ("second startup run failed with exit code {0}" -f $secondRun.exit_code)
}

if ($secondRun.output -notmatch 'All declared services already healthy\. Reusing existing Phase 2 stack\.') {
    Add-Failure -Failures $failures -Message "second startup run did not report reuse of an already-healthy declared stack"
}

if ($secondRun.output -notmatch 'Phase 2 startup sequence completed: topology validated, preflight passed, services started or reused, health checks passed, provider warmed\.') {
    Add-Failure -Failures $failures -Message "second startup run did not report the idempotent startup completion summary"
}

foreach ($service in $services) {
    $serviceName = if ([string]::IsNullOrWhiteSpace([string]$service.startup_name)) { [string]$service.name } else { [string]$service.startup_name }
    $port = [int]$service.port

    if ($secondRun.output -notmatch [regex]::Escape("$serviceName already healthy. Reusing existing process.")) {
        Add-Failure -Failures $failures -Message ("second startup run did not report reuse for service '{0}'" -f $serviceName)
    }

    if ($secondRun.output -match [regex]::Escape("Started $serviceName on port $port")) {
        Add-Failure -Failures $failures -Message ("second startup run still started service '{0}' on port {1}" -f $serviceName, $port)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { 'passed' } else { 'failed' })
    repo_root = $resolvedRepoRoot
    first_run_exit_code = $firstRun.exit_code
    second_run_exit_code = $secondRun.exit_code
    service_names = @($services | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace([string]$_.startup_name)) { [string]$_.name } else { [string]$_.startup_name }
    })
    failures = @($failures)
}

Write-Host ""
Write-Host "Runtime stack startup idempotence validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne 'passed') {
    throw "Runtime stack startup idempotence validation failed."
}

Write-Host ""
Write-Host "Runtime stack startup idempotence validation passed." -ForegroundColor Green
