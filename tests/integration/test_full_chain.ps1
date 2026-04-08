param(
    [string]$GatewayBaseUrl = "http://127.0.0.1:8000",
    [string]$SessionEngineBaseUrl = "http://127.0.0.1:8002",
    [string]$EidonBaseUrl = "http://127.0.0.1:8003"
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
Assert-Equal -Name "eidon storage backend" -Actual $response.eidon_result.storage_backend -Expected "local_json"

$artifactId = $response.eidon_result.artifact_id
Assert-Equal -Name "artifact id" -Actual $artifactId -Expected "artifact-session-sig-001"

$sessionId = $response.session_result.session_id
$persistedSession = Invoke-RestMethod -Uri "$SessionEngineBaseUrl/sessions/$sessionId" -Method Get
$persistedSessionJson = $persistedSession | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $persistedSessionJson

Assert-Equal -Name "persisted session lookup status" -Actual $persistedSession.status -Expected "found"
Assert-Equal -Name "persisted session lookup service" -Actual $persistedSession.service -Expected "session-engine"

if ($null -eq $persistedSession.session) {
    throw "Missing persisted session object in lookup response."
}

Assert-Equal -Name "persisted session id" -Actual $persistedSession.session.session_id -Expected "session-sig-001"
Assert-Equal -Name "persisted signal id" -Actual $persistedSession.session.signal_id -Expected "sig-001"
Assert-Equal -Name "persisted session storage backend" -Actual $persistedSession.session.storage_backend -Expected "local_json"
Assert-Equal -Name "persisted session status" -Actual $persistedSession.session.status -Expected "started"

$persistedArtifact = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$artifactId" -Method Get
$persistedArtifactJson = $persistedArtifact | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $persistedArtifactJson

Assert-Equal -Name "persisted artifact lookup status" -Actual $persistedArtifact.status -Expected "found"
Assert-Equal -Name "persisted artifact lookup service" -Actual $persistedArtifact.service -Expected "eidon-orchestrator"

if ($null -eq $persistedArtifact.artifact) {
    throw "Missing persisted artifact object in lookup response."
}

Assert-Equal -Name "persisted artifact id" -Actual $persistedArtifact.artifact.artifact_id -Expected "artifact-session-sig-001"
Assert-Equal -Name "persisted artifact session id" -Actual $persistedArtifact.artifact.session_id -Expected "session-sig-001"
Assert-Equal -Name "persisted artifact signal id" -Actual $persistedArtifact.artifact.signal_id -Expected "sig-001"
Assert-Equal -Name "persisted artifact status" -Actual $persistedArtifact.artifact.status -Expected "orchestrated"
Assert-Equal -Name "persisted artifact storage backend" -Actual $persistedArtifact.artifact.storage_backend -Expected "local_json"

Write-Host ""
Write-Host "Full chain integration test with session and artifact persistence passed." -ForegroundColor Green
