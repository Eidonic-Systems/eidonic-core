param(
    [string]$RepoRoot = ".",
    [int]$MaxAttempts = 30,
    [int]$SleepSeconds = 2
)

$ErrorActionPreference = "Stop"

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

function Wait-ForServiceHealth {
    param(
        $Service,
        [int]$MaxAttempts,
        [int]$SleepSeconds
    )

    $name = [string]$Service.name
    $healthUrl = [string]$Service.health_url
    $port = [int]$Service.port
    $checkProviderStatus = [bool]$Service.check_provider_status

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10

            if ($null -eq $response) {
                throw "$name returned no response."
            }

            if ($response.status -ne "ok") {
                throw "$name health status was '$($response.status)'."
            }

            if ($checkProviderStatus -and ($response.PSObject.Properties.Name -contains "provider")) {
                if ($response.provider.status -ne "ok") {
                    throw "$name provider status was '$($response.provider.status)'."
                }
            }

            return [pscustomobject]@{
                name = $name
                port = $port
                health_url = $healthUrl
                status = $response.status
            }
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw "$name readiness failed after $MaxAttempts attempts. Last error: $($_.Exception.Message)"
            }

            Write-Host ("Waiting for {0} on port {1} ({2}/{3})..." -f $name, $port, $attempt, $MaxAttempts) -ForegroundColor Yellow
            Start-Sleep -Seconds $SleepSeconds
        }
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifest = Get-ServiceTopology -ResolvedRepoRoot $resolvedRepoRoot

Write-Host ""
Write-Host "Checking Phase 2 startup readiness..." -ForegroundColor Yellow

$results = @()

foreach ($service in $manifest.services) {
    $results += Wait-ForServiceHealth -Service $service -MaxAttempts $MaxAttempts -SleepSeconds $SleepSeconds
}

$summary = [ordered]@{
    status = "passed"
    manifest_version = [string]$manifest.manifest_version
    total_services = $results.Count
    results = $results
}

Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 8)
Write-Host ""
Write-Host "Phase 2 startup readiness check passed." -ForegroundColor Green
