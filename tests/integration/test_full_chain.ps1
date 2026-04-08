param(
    [string]$GatewayBaseUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$payloadPath = Join-Path $repoRoot "services\signal-gateway\examples\sample_signal_event.json"

if (-not (Test-Path $payloadPath)) {
    throw "Missing payload file: $payloadPath"
}

$body = Get-Content $payloadPath -Raw
$response = Invoke-RestMethod -Uri "$GatewayBaseUrl/signals/ingest" -Method Post -ContentType "application/json" -Body $body

$responseJson = $response | ConvertTo-Json -Depth 12
Write-Host $responseJson

function Assert-Equal {
    param(
        [string]$Name,
        $Actual,
        $Expected
    )

    if ($Actual -ne $Expected) {
        throw "$Name failed. Expected '$Expected' but got '$Actual'."
    }
}

Assert-Equal -Name "gateway status" -Actual $response.status -Expected "accepted"
Assert-Equal -Name "gateway service" -Actual $response.service -Expected "signal-gateway"
Assert-Equal -Name "gateway signal id" -Actual $response.received_signal_id -Expected "sig-001"

if ($null -eq $response.herald_result) {
    throw "Missing herald_result in response."
}
Assert-Equal -Name "herald status" -Actual $response.herald_result.status -Expected "reviewed"
Assert-Equal -Name "herald service" -Actual $response.herald_result.service -Expected "herald-service"
Assert-Equal -Name "herald threshold result" -Actual $response.herald_result.threshold_result -Expected "pass"

if ($null -eq $response.session_result) {
    throw "Missing session_result in response."
}
Assert-Equal -Name "session status" -Actual $response.session_result.status -Expected "started"
Assert-Equal -Name "session service" -Actual $response.session_result.service -Expected "session-engine"
Assert-Equal -Name "session id" -Actual $response.session_result.session_id -Expected "session-sig-001"

if ($null -eq $response.eidon_result) {
    throw "Missing eidon_result in response."
}
Assert-Equal -Name "eidon status" -Actual $response.eidon_result.status -Expected "orchestrated"
Assert-Equal -Name "eidon service" -Actual $response.eidon_result.service -Expected "eidon-orchestrator"
Assert-Equal -Name "eidon session id" -Actual $response.eidon_result.session_id -Expected "session-sig-001"

Write-Host ""
Write-Host "Full chain integration test passed." -ForegroundColor Green
