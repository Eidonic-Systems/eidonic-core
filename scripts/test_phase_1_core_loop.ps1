param(
    [string]$SignalGatewayBaseUrl = "http://127.0.0.1:8000",
    [string]$HeraldBaseUrl = "http://127.0.0.1:8001",
    [string]$SessionEngineBaseUrl = "http://127.0.0.1:8002",
    [string]$EidonBaseUrl = "http://127.0.0.1:8003"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")

$signalPayloadPath = Join-Path $repoRoot "services\signal-gateway\examples\sample_signal_event.json"
$heraldPayloadPath = Join-Path $repoRoot "services\herald-service\examples\sample_threshold_check.json"
$sessionPayloadPath = Join-Path $repoRoot "services\session-engine\examples\sample_session_start.json"
$eidonPayloadPath = Join-Path $repoRoot "services\eidon-orchestrator\examples\sample_orchestration_request.json"

function Get-JsonBody {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Required payload file not found: $Path"
    }

    return Get-Content $Path -Raw
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $true)]
        [hashtable]$Expected
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    Write-Host "POST $Uri"

    $response = Invoke-RestMethod -Uri $Uri -Method Post -ContentType "application/json" -Body $Body
    $responseJson = $response | ConvertTo-Json -Depth 10
    Write-Host $responseJson

    foreach ($key in $Expected.Keys) {
        $actual = $response.$key
        $expectedValue = $Expected[$key]

        if ($actual -ne $expectedValue) {
            throw "$Name failed validation for '$key'. Expected '$expectedValue' but got '$actual'."
        }
    }

    Write-Host "$Name passed." -ForegroundColor Green
    return $response
}

$signalBody = Get-JsonBody -Path $signalPayloadPath
$heraldBody = Get-JsonBody -Path $heraldPayloadPath
$sessionBody = Get-JsonBody -Path $sessionPayloadPath
$eidonBody = Get-JsonBody -Path $eidonPayloadPath

Invoke-Step `
    -Name "Signal Gateway" `
    -Uri "$SignalGatewayBaseUrl/signals/ingest" `
    -Body $signalBody `
    -Expected @{
        status = "accepted"
        service = "signal-gateway"
        received_signal_id = "sig-001"
    }

Invoke-Step `
    -Name "Herald Service" `
    -Uri "$HeraldBaseUrl/threshold/check" `
    -Body $heraldBody `
    -Expected @{
        status = "reviewed"
        service = "herald-service"
        signal_id = "sig-001"
        threshold_result = "pass"
    }

Invoke-Step `
    -Name "Session Engine" `
    -Uri "$SessionEngineBaseUrl/sessions/start" `
    -Body $sessionBody `
    -Expected @{
        status = "started"
        service = "session-engine"
        session_id = "session-sig-001"
        signal_id = "sig-001"
    }

Invoke-Step `
    -Name "Eidon Orchestrator" `
    -Uri "$EidonBaseUrl/orchestrate" `
    -Body $eidonBody `
    -Expected @{
        status = "orchestrated"
        service = "eidon-orchestrator"
        session_id = "session-sig-001"
        signal_id = "sig-001"
    }

Write-Host ""
Write-Host "Phase 1 core loop local runner completed successfully." -ForegroundColor Green
