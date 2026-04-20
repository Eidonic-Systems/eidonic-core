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

function Test-BooleanValue {
    param(
        $Value
    )

    return ($Value -is [bool])
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\service_topology_manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing service topology manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    Add-Failure -Failures $failures -Message "missing manifest_version"
}

$services = @($manifest.services)
if ($services.Count -eq 0) {
    Add-Failure -Failures $failures -Message "manifest has no services"
}

$serviceNames = @{}
$ports = @{}
$results = [System.Collections.ArrayList]::new()

foreach ($service in $services) {
    $serviceFailures = [System.Collections.ArrayList]::new()

    $name = [string]$service.name
    $port = $service.port
    $healthUrl = [string]$service.health_url
    $serviceRoot = [string]$service.service_root
    $processMatchPatterns = @($service.process_match_patterns)
    $checkProviderStatus = $service.check_provider_status
    $startupName = [string]$service.startup_name
    $startupWorkdir = [string]$service.startup_workdir
    $startupCommand = [string]$service.startup_command

    if ([string]::IsNullOrWhiteSpace($name)) {
        Add-Failure -Failures $serviceFailures -Message "missing name"
    }
    elseif ($serviceNames.ContainsKey($name)) {
        Add-Failure -Failures $serviceFailures -Message ("duplicate name '{0}'" -f $name)
    }
    else {
        $serviceNames[$name] = $true
    }

    if ($null -eq $port) {
        Add-Failure -Failures $serviceFailures -Message "missing port"
    }
    elseif (-not ($port -is [int] -or $port -is [long])) {
        Add-Failure -Failures $serviceFailures -Message ("port '{0}' is not an integer" -f $port)
    }
    elseif ($port -lt 1 -or $port -gt 65535) {
        Add-Failure -Failures $serviceFailures -Message ("port '{0}' is out of range" -f $port)
    }
    elseif ($ports.ContainsKey([int]$port)) {
        Add-Failure -Failures $serviceFailures -Message ("duplicate port '{0}'" -f $port)
    }
    else {
        $ports[[int]$port] = $true
    }

    if ([string]::IsNullOrWhiteSpace($healthUrl)) {
        Add-Failure -Failures $serviceFailures -Message "missing health_url"
    }
    elseif ($healthUrl -notmatch '^http://127\.0\.0\.1:(\d+)/health$') {
        Add-Failure -Failures $serviceFailures -Message ("health_url '{0}' is invalid" -f $healthUrl)
    }
    elseif ($null -ne $port -and ($healthUrl -notmatch (":{0}/health$" -f [int]$port))) {
        Add-Failure -Failures $serviceFailures -Message ("health_url '{0}' does not match port '{1}'" -f $healthUrl, $port)
    }

    if ([string]::IsNullOrWhiteSpace($serviceRoot)) {
        Add-Failure -Failures $serviceFailures -Message "missing service_root"
    }
    else {
        $serviceRootPath = Join-Path $resolvedRepoRoot $serviceRoot
        if (-not (Test-Path $serviceRootPath)) {
            Add-Failure -Failures $serviceFailures -Message ("service_root path does not exist '{0}'" -f $serviceRoot)
        }
    }

    if ($processMatchPatterns.Count -eq 0) {
        Add-Failure -Failures $serviceFailures -Message "missing process_match_patterns"
    }
    else {
        $usablePatterns = @($processMatchPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        if ($usablePatterns.Count -eq 0) {
            Add-Failure -Failures $serviceFailures -Message "process_match_patterns contains no usable values"
        }
    }

    if (-not (Test-BooleanValue -Value $checkProviderStatus)) {
        Add-Failure -Failures $serviceFailures -Message "check_provider_status must be boolean"
    }

    if ([string]::IsNullOrWhiteSpace($startupName)) {
        Add-Failure -Failures $serviceFailures -Message "missing startup_name"
    }

    if ([string]::IsNullOrWhiteSpace($startupWorkdir)) {
        Add-Failure -Failures $serviceFailures -Message "missing startup_workdir"
    }
    else {
        $startupWorkdirPath = Join-Path $resolvedRepoRoot $startupWorkdir
        if (-not (Test-Path $startupWorkdirPath)) {
            Add-Failure -Failures $serviceFailures -Message ("startup_workdir path does not exist '{0}'" -f $startupWorkdir)
        }
    }

    if ([string]::IsNullOrWhiteSpace($startupCommand)) {
        Add-Failure -Failures $serviceFailures -Message "missing startup_command"
    }
    elseif ($null -ne $port -and $startupCommand -notmatch ("--port\s+{0}(\D|$)" -f [int]$port)) {
        Add-Failure -Failures $serviceFailures -Message ("startup_command does not include declared port '{0}'" -f $port)
    }

    $status = if ($serviceFailures.Count -eq 0) { "passed" } else { "failed" }

    [void]$results.Add([pscustomobject]@{
        service = $name
        status = $status
        failures = @($serviceFailures)
    })

    foreach ($failure in $serviceFailures) {
        $prefix = if ([string]::IsNullOrWhiteSpace($name)) { "<unnamed-service>" } else { $name }
        Add-Failure -Failures $failures -Message ("{0}: {1}" -f $prefix, $failure)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    total_services = $services.Count
    failed_services = @($results | Where-Object { $_.status -eq "failed" }).Count
    results = $results
    failures = @($failures)
}

Write-Host ""
Write-Host "Service topology manifest validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne "passed") {
    throw "Service topology manifest validation failed."
}

Write-Host ""
Write-Host "Service topology manifest validation passed." -ForegroundColor Green
