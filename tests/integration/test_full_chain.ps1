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
Assert-Equal -Name "session storage backend" -Actual $response.session_result.storage_backend -Expected "postgres"

if ($null -eq $response.eidon_result) {
    throw "Missing eidon_result in response."
}
Assert-Equal -Name "eidon status" -Actual $response.eidon_result.status -Expected "orchestrated"
Assert-Equal -Name "eidon service" -Actual $response.eidon_result.service -Expected "eidon-orchestrator"
Assert-Equal -Name "eidon session id" -Actual $response.eidon_result.session_id -Expected "session-sig-001"
Assert-Equal -Name "eidon storage backend" -Actual $response.eidon_result.storage_backend -Expected "postgres"

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
Assert-Equal -Name "persisted session storage backend" -Actual $persistedSession.session.storage_backend -Expected "postgres"
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
Assert-Equal -Name "persisted artifact storage backend" -Actual $persistedArtifact.artifact.storage_backend -Expected "postgres"

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
  -Expected "postgres"

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
  -Expected "postgres"

$signalId = $response.received_signal_id

$signalList = Invoke-RestMethod -Uri "$GatewayBaseUrl/signals" `
  -Method Get

$signalListJson = $signalList | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $signalListJson

Assert-Equal -Name "signal list status" `
  -Actual $signalList.status `
  -Expected "found"

Assert-Equal -Name "signal list service" `
  -Actual $signalList.service `
  -Expected "signal-gateway"

if ($null -eq $signalList.signals) {
  throw "Missing signals list in Signal Gateway list response."
}

if ($signalList.count -lt 1) {
  throw "Expected at least one signal record in Signal Gateway list response."
}

$signalFromList = $signalList.signals | Where-Object { $_.signal_id -eq $signalId } | Select-Object -First 1

if ($null -eq $signalFromList) {
  throw "Expected signal id $signalId was not found in Signal Gateway list response."
}

$sessionId = $response.session_result.session_id

$sessionList = Invoke-RestMethod -Uri "$SessionEngineBaseUrl/sessions" `
  -Method Get

$sessionListJson = $sessionList | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $sessionListJson

Assert-Equal -Name "session list status" `
  -Actual $sessionList.status `
  -Expected "listed"

Assert-Equal -Name "session list service" `
  -Actual $sessionList.service `
  -Expected "session-engine"

if ($null -eq $sessionList.sessions) {
  throw "Missing sessions list in Session Engine list response."
}

if ($sessionList.count -lt 1) {
  throw "Expected at least one session record in Session Engine list response."
}

$sessionFromList = $sessionList.sessions | Where-Object { $_.session_id -eq $sessionId } | Select-Object -First 1

if ($null -eq $sessionFromList) {
  throw "Expected session id $sessionId was not found in Session Engine list response."
}

$signalGatewayHealth = Invoke-RestMethod -Uri "$GatewayBaseUrl/health" `
  -Method Get

$signalGatewayHealthJson = $signalGatewayHealth | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $signalGatewayHealthJson

Assert-Equal -Name "signal gateway health status" `
  -Actual $signalGatewayHealth.status `
  -Expected "ok"

Assert-Equal -Name "signal gateway health service" `
  -Actual $signalGatewayHealth.service `
  -Expected "signal-gateway"

if ($null -eq $signalGatewayHealth.store) {
  throw "Missing store object in Signal Gateway health response."
}

Assert-Equal -Name "signal gateway store status" `
  -Actual $signalGatewayHealth.store.status `
  -Expected "ok"

Assert-Equal -Name "signal gateway store backend" `
  -Actual $signalGatewayHealth.store.backend `
  -Expected "postgres"

$heraldHealth = Invoke-RestMethod -Uri "http://127.0.0.1:8001/health" `
  -Method Get

$heraldHealthJson = $heraldHealth | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $heraldHealthJson

Assert-Equal -Name "herald health status" `
  -Actual $heraldHealth.status `
  -Expected "ok"

Assert-Equal -Name "herald health service" `
  -Actual $heraldHealth.service `
  -Expected "herald-service"

if ($null -eq $heraldHealth.store) {
  throw "Missing store object in Herald health response."
}

Assert-Equal -Name "herald store status" `
  -Actual $heraldHealth.store.status `
  -Expected "ok"

Assert-Equal -Name "herald store backend" `
  -Actual $heraldHealth.store.backend `
  -Expected "postgres"

$sessionEngineHealth = Invoke-RestMethod -Uri "$SessionEngineBaseUrl/health" `
  -Method Get

$sessionEngineHealthJson = $sessionEngineHealth | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $sessionEngineHealthJson

Assert-Equal -Name "session engine health status" `
  -Actual $sessionEngineHealth.status `
  -Expected "ok"

Assert-Equal -Name "session engine health service" `
  -Actual $sessionEngineHealth.service `
  -Expected "session-engine"

if ($null -eq $sessionEngineHealth.store) {
  throw "Missing store object in Session Engine health response."
}

Assert-Equal -Name "session engine store status" `
  -Actual $sessionEngineHealth.store.status `
  -Expected "ok"

Assert-Equal -Name "session engine store backend" `
  -Actual $sessionEngineHealth.store.backend `
  -Expected "postgres"

$eidonHealth = Invoke-RestMethod -Uri "$EidonBaseUrl/health" `
  -Method Get

$eidonHealthJson = $eidonHealth | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $eidonHealthJson

Assert-Equal -Name "eidon health status" `
  -Actual $eidonHealth.status `
  -Expected "ok"

Assert-Equal -Name "eidon health service" `
  -Actual $eidonHealth.service `
  -Expected "eidon-orchestrator"

if ($null -eq $eidonHealth.artifact_store) {
  throw "Missing artifact_store object in Eidon Orchestrator health response."
}

if ($null -eq $eidonHealth.lineage_store) {
  throw "Missing lineage_store object in Eidon Orchestrator health response."
}

Assert-Equal -Name "eidon artifact store status" `
  -Actual $eidonHealth.artifact_store.status `
  -Expected "ok"

Assert-Equal -Name "eidon artifact store backend" `
  -Actual $eidonHealth.artifact_store.backend `
  -Expected "postgres"

Assert-Equal -Name "eidon lineage store status" `
  -Actual $eidonHealth.lineage_store.status `
  -Expected "ok"

Assert-Equal -Name "eidon lineage store backend" `
  -Actual $eidonHealth.lineage_store.backend `
  -Expected "postgres"

$signalId = $response.received_signal_id
$sessionId = $response.session_result.session_id
$artifactId = $response.eidon_result.artifact_id

$signalListLimited = Invoke-RestMethod -Uri "$GatewayBaseUrl/signals?limit=1" `
  -Method Get

$signalListLimitedJson = $signalListLimited | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $signalListLimitedJson

Assert-Equal -Name "signal limited list status" `
  -Actual $signalListLimited.status `
  -Expected "found"

Assert-Equal -Name "signal limited list service" `
  -Actual $signalListLimited.service `
  -Expected "signal-gateway"

Assert-Equal -Name "signal limited list count" `
  -Actual $signalListLimited.count `
  -Expected 1

if ($null -eq $signalListLimited.signals) {
  throw "Missing signals list in Signal Gateway limited list response."
}

$signalFromLimitedList = $signalListLimited.signals | Select-Object -First 1

if ($null -eq $signalFromLimitedList) {
  throw "Missing signal record in Signal Gateway limited list response."
}

Assert-Equal -Name "signal limited list first id" `
  -Actual $signalFromLimitedList.signal_id `
  -Expected $signalId

$thresholdListLimited = Invoke-RestMethod -Uri "http://127.0.0.1:8001/thresholds?limit=1" `
  -Method Get

$thresholdListLimitedJson = $thresholdListLimited | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $thresholdListLimitedJson

Assert-Equal -Name "threshold limited list status" `
  -Actual $thresholdListLimited.status `
  -Expected "found"

Assert-Equal -Name "threshold limited list service" `
  -Actual $thresholdListLimited.service `
  -Expected "herald-service"

Assert-Equal -Name "threshold limited list count" `
  -Actual $thresholdListLimited.count `
  -Expected 1

if ($null -eq $thresholdListLimited.thresholds) {
  throw "Missing thresholds list in Herald limited list response."
}

$thresholdFromLimitedList = $thresholdListLimited.thresholds | Select-Object -First 1

if ($null -eq $thresholdFromLimitedList) {
  throw "Missing threshold record in Herald limited list response."
}

Assert-Equal -Name "threshold limited list first signal id" `
  -Actual $thresholdFromLimitedList.signal_id `
  -Expected $signalId

$sessionListLimited = Invoke-RestMethod -Uri "$SessionEngineBaseUrl/sessions?limit=1" `
  -Method Get

$sessionListLimitedJson = $sessionListLimited | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $sessionListLimitedJson

Assert-Equal -Name "session limited list status" `
  -Actual $sessionListLimited.status `
  -Expected "listed"

Assert-Equal -Name "session limited list service" `
  -Actual $sessionListLimited.service `
  -Expected "session-engine"

Assert-Equal -Name "session limited list count" `
  -Actual $sessionListLimited.count `
  -Expected 1

if ($null -eq $sessionListLimited.sessions) {
  throw "Missing sessions list in Session Engine limited list response."
}

$sessionFromLimitedList = $sessionListLimited.sessions | Select-Object -First 1

if ($null -eq $sessionFromLimitedList) {
  throw "Missing session record in Session Engine limited list response."
}

Assert-Equal -Name "session limited list first id" `
  -Actual $sessionFromLimitedList.session_id `
  -Expected $sessionId

$artifactListLimited = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts?limit=1" `
  -Method Get

$artifactListLimitedJson = $artifactListLimited | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $artifactListLimitedJson

Assert-Equal -Name "artifact limited list status" `
  -Actual $artifactListLimited.status `
  -Expected "found"

Assert-Equal -Name "artifact limited list service" `
  -Actual $artifactListLimited.service `
  -Expected "eidon-orchestrator"

Assert-Equal -Name "artifact limited list count" `
  -Actual $artifactListLimited.count `
  -Expected 1

if ($null -eq $artifactListLimited.artifacts) {
  throw "Missing artifacts list in Orchestrator limited artifact list response."
}

$artifactFromLimitedList = $artifactListLimited.artifacts | Select-Object -First 1

if ($null -eq $artifactFromLimitedList) {
  throw "Missing artifact record in Orchestrator limited artifact list response."
}

Assert-Equal -Name "artifact limited list first id" `
  -Actual $artifactFromLimitedList.artifact_id `
  -Expected $artifactId

$lineageListLimited = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage?limit=1" `
  -Method Get

$lineageListLimitedJson = $lineageListLimited | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $lineageListLimitedJson

Assert-Equal -Name "lineage limited list status" `
  -Actual $lineageListLimited.status `
  -Expected "found"

Assert-Equal -Name "lineage limited list service" `
  -Actual $lineageListLimited.service `
  -Expected "eidon-orchestrator"

Assert-Equal -Name "lineage limited list count" `
  -Actual $lineageListLimited.count `
  -Expected 1

if ($null -eq $lineageListLimited.lineage) {
  throw "Missing lineage list in Orchestrator limited lineage list response."
}

$lineageFromLimitedList = $lineageListLimited.lineage | Select-Object -First 1

if ($null -eq $lineageFromLimitedList) {
  throw "Missing lineage record in Orchestrator limited lineage list response."
}

Assert-Equal -Name "lineage limited list first artifact id" `
  -Actual $lineageFromLimitedList.artifact_id `
  -Expected $artifactId

Write-Host "Full chain integration test with list limit surfaces passed." -ForegroundColor Green















