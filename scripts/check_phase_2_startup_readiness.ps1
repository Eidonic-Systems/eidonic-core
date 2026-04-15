param(
    [int]$SignalGatewayPort = 8000,
    [int]$SessionEnginePort = 8001,
    [int]$HeraldServicePort = 8002,
    [int]$EidonOrchestratorPort = 8003,
    [int]$MaxAttempts = 30,
    [int]$SleepSeconds = 2
)

$ErrorActionPreference = "Stop"

function Wait-ForServiceHealth {
    param(
        [string]$Name,
        [string]$HealthUrl,
        [int]$Port
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 10

            if ($null -eq $response) {
                throw "$Name returned no response."
            }

            if ($response.status -ne "ok") {
                throw "$Name health status was '$($response.status)'."
            }

            if ($response.PSObject.Properties.Name -contains "provider") {
                if ($response.provider.status -ne "ok") {
                    throw "$Name provider status was '$($response.provider.status)'."
                }
            }

            return [pscustomobject]@{
                name = $Name
                port = $Port
                health_url = $HealthUrl
                status = $response.status
            }
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw "$Name readiness failed after $MaxAttempts attempts. Last error: $($_.Exception.Message)"
            }

            Write-Host ("Waiting for {0} on port {1} ({2}/{3})..." -f $Name, $Port, $attempt, $MaxAttempts) -ForegroundColor Yellow
            Start-Sleep -Seconds $SleepSeconds
        }
    }
}

Write-Host ""
Write-Host "Checking Phase 2 startup readiness..." -ForegroundColor Yellow

$results = @()

$results += Wait-ForServiceHealth -Name "signal-gateway" -HealthUrl ("http://127.0.0.1:{0}/health" -f $SignalGatewayPort) -Port $SignalGatewayPort
$results += Wait-ForServiceHealth -Name "session-engine" -HealthUrl ("http://127.0.0.1:{0}/health" -f $SessionEnginePort) -Port $SessionEnginePort
$results += Wait-ForServiceHealth -Name "herald-service" -HealthUrl ("http://127.0.0.1:{0}/health" -f $HeraldServicePort) -Port $HeraldServicePort
$results += Wait-ForServiceHealth -Name "eidon-orchestrator" -HealthUrl ("http://127.0.0.1:{0}/health" -f $EidonOrchestratorPort) -Port $EidonOrchestratorPort

$summary = [ordered]@{
    status = "passed"
    total_services = $results.Count
    results = $results
}

Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 8)
Write-Host ""
Write-Host "Phase 2 startup readiness check passed." -ForegroundColor Green
