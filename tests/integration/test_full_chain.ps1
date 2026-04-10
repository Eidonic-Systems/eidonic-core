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
$artifactId = $response.eidon_result.artifact_id

$persistedLineage = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$artifactId" `
  -Method Get

$persistedLineageJson = $persistedLineage | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $persistedLineageJson

Assert-Equal -Name "persisted lineage lookup status" `
  -Actual $persistedLineage.status `
  -Expected "found"

Assert-Equal -Name "persisted lineage lookup service" `
  -Actual $persistedLineage.service `
  -Expected "eidon-orchestrator"

if ($null -eq $persistedLineage.lineage) {
  throw "Missing persisted lineage object in lookup response."
}

Assert-Equal -Name "persisted lineage artifact id" `
  -Actual $persistedLineage.lineage.artifact_id `
  -Expected $artifactId

$artifactList = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts" `
  -Method Get

$artifactListJson = $artifactList | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $artifactListJson

Assert-Equal -Name "artifact list status" `
  -Actual $artifactList.status `
  -Expected "found"

Assert-Equal -Name "artifact list service" `
  -Actual $artifactList.service `
  -Expected "eidon-orchestrator"

if ($null -eq $artifactList.artifacts) {
  throw "Missing artifacts list in orchestrator artifact list response."
}

if ($artifactList.count -lt 1) {
  throw "Expected at least one artifact in orchestrator artifact list response."
}

$artifactFromList = $artifactList.artifacts | Where-Object { $_.artifact_id -eq $artifactId } | Select-Object -First 1

if ($null -eq $artifactFromList) {
  throw "Expected artifact id $artifactId was not found in orchestrator artifact list response."
}

$lineageList = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage" `
  -Method Get

$lineageListJson = $lineageList | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $lineageListJson

Assert-Equal -Name "lineage list status" `
  -Actual $lineageList.status `
  -Expected "found"

Assert-Equal -Name "lineage list service" `
  -Actual $lineageList.service `
  -Expected "eidon-orchestrator"

if ($null -eq $lineageList.lineage) {
  throw "Missing lineage list in orchestrator lineage list response."
}

if ($lineageList.count -lt 1) {
  throw "Expected at least one lineage record in orchestrator lineage list response."
}

$lineageFromList = $lineageList.lineage | Where-Object { $_.artifact_id -eq $artifactId } | Select-Object -First 1

if ($null -eq $lineageFromList) {
  throw "Expected artifact id $artifactId was not found in orchestrator lineage list response."
}

$signalId = $response.received_signal_id

$persistedThreshold = Invoke-RestMethod -Uri "http://127.0.0.1:8001/thresholds/$signalId" `
  -Method Get

$persistedThresholdJson = $persistedThreshold | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $persistedThresholdJson

Assert-Equal -Name "persisted threshold lookup status" `
  -Actual $persistedThreshold.status `
  -Expected "found"

Assert-Equal -Name "persisted threshold lookup service" `
  -Actual $persistedThreshold.service `
  -Expected "herald-service"

if ($null -eq $persistedThreshold.threshold) {
  throw "Missing persisted threshold object in lookup response."
}

Assert-Equal -Name "persisted threshold id" `
  -Actual $persistedThreshold.threshold.threshold_id `
  -Expected "threshold-$signalId"

Assert-Equal -Name "persisted threshold signal id" `
  -Actual $persistedThreshold.threshold.signal_id `
  -Expected $signalId

Assert-Equal -Name "persisted threshold result" `
  -Actual $persistedThreshold.threshold.threshold_result `
  -Expected "pass"

Assert-Equal -Name "persisted threshold status" `
  -Actual $persistedThreshold.threshold.status `
  -Expected "reviewed"

Assert-Equal -Name "persisted threshold storage backend" `
  -Actual $persistedThreshold.threshold.storage_backend `
  -Expected "local_json"

$thresholdList = Invoke-RestMethod -Uri "http://127.0.0.1:8001/thresholds" `
  -Method Get

$thresholdListJson = $thresholdList | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $thresholdListJson

Assert-Equal -Name "threshold list status" `
  -Actual $thresholdList.status `
  -Expected "found"

Assert-Equal -Name "threshold list service" `
  -Actual $thresholdList.service `
  -Expected "herald-service"

if ($null -eq $thresholdList.thresholds) {
  throw "Missing thresholds list in Herald threshold list response."
}

if ($thresholdList.count -lt 1) {
  throw "Expected at least one threshold record in Herald threshold list response."
}

$thresholdFromList = $thresholdList.thresholds | Where-Object { $_.signal_id -eq $signalId } | Select-Object -First 1

if ($null -eq $thresholdFromList) {
  throw "Expected signal id $signalId was not found in Herald threshold list response."
}

$signalId = $response.received_signal_id

$persistedSignal = Invoke-RestMethod -Uri "$GatewayBaseUrl/signals/$signalId" `
  -Method Get

$persistedSignalJson = $persistedSignal | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $persistedSignalJson

Assert-Equal -Name "persisted signal lookup status" `
  -Actual $persistedSignal.status `
  -Expected "found"

Assert-Equal -Name "persisted signal lookup service" `
  -Actual $persistedSignal.service `
  -Expected "signal-gateway"

if ($null -eq $persistedSignal.signal) {
  throw "Missing persisted signal object in lookup response."
}

Assert-Equal -Name "persisted signal id" `
  -Actual $persistedSignal.signal.signal_id `
  -Expected $signalId

Assert-Equal -Name "persisted signal type" `
  -Actual $persistedSignal.signal.signal_type `
  -Expected "user_message"

Assert-Equal -Name "persisted signal source" `
  -Actual $persistedSignal.signal.source `
  -Expected "chat"

Assert-Equal -Name "persisted signal status" `
  -Actual $persistedSignal.signal.status `
  -Expected "accepted"

Assert-Equal -Name "persisted signal storage backend" `
  -Actual $persistedSignal.signal.storage_backend `
  -Expected "local_json"

Write-Host "Full chain integration test with signal, threshold, session, artifact, lineage, orchestrator list surfaces, and Herald list surfaces passed." -ForegroundColor Green






