param(
    [string]$GatewayBaseUrl = "http://127.0.0.1:8000",
    [string]$SessionEngineBaseUrl = "http://127.0.0.1:8002"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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
Assert-Equal -Name "session storage backend" -Actual $response.session_result.storage_backend -Expected "local_json"

if ($null -eq $response.eidon_result) {
    throw "Missing eidon_result in response."
}
Assert-Equal -Name "eidon status" -Actual $response.eidon_result.status -Expected "orchestrated"
Assert-Equal -Name "eidon service" -Actual $response.eidon_result.service -Expected "eidon-orchestrator"
Assert-Equal -Name "eidon session id" -Actual $response.eidon_result.session_id -Expected "session-sig-001"

$sessionId = $response.session_result.session_id
$persisted = Invoke-RestMethod -Uri "$SessionEngineBaseUrl/sessions/$sessionId" -Method Get
$persistedJson = $persisted | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $persistedJson

Assert-Equal -Name "persisted lookup status" -Actual $persisted.status -Expected "found"
Assert-Equal -Name "persisted lookup service" -Actual $persisted.service -Expected "session-engine"

if ($null -eq $persisted.session) {
    throw "Missing persisted session object in lookup response."
}

Assert-Equal -Name "persisted session id" -Actual $persisted.session.session_id -Expected "session-sig-001"
Assert-Equal -Name "persisted signal id" -Actual $persisted.session.signal_id -Expected "sig-001"
Assert-Equal -Name "persisted storage backend" -Actual $persisted.session.storage_backend -Expected "local_json"
Assert-Equal -Name "persisted session status" -Actual $persisted.session.status -Expected "started"

Write-Host ""
Write-Host "Full chain integration test with session persistence passed." -ForegroundColor Green
