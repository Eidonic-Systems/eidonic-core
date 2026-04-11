param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$ExpectedProviderBackend = "ollama",
    [string]$ExpectedMissingModel = "definitely-missing-model"
)

$ErrorActionPreference = "Stop"

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

$runId = Get-Date -Format "yyyyMMddHHmmss"
$sessionId = "session-provider-failure-$runId"
$signalId = "sig-provider-failure-$runId"

$payload = @{
    session_id = $sessionId
    signal_id = $signalId
    signal_type = "user_message"
    source = "chat"
    threshold_result = "pass"
    intent = "Respond to the user message: test provider failure semantics"
    content = @{
        text = "Provider failure semantics test."
    }
} | ConvertTo-Json -Depth 12

$response = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
  -Method Post `
  -ContentType "application/json" `
  -Body $payload

$responseJson = $response | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $responseJson

Assert-Equal -Name "provider failure response status" `
  -Actual $response.status `
  -Expected "provider_failed"

Assert-Equal -Name "provider failure response service" `
  -Actual $response.service `
  -Expected "eidon-orchestrator"

Assert-Equal -Name "provider failure response backend" `
  -Actual $response.provider_backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "provider failure response model" `
  -Actual $response.provider_model `
  -Expected $ExpectedMissingModel

Assert-Equal -Name "provider failure response provider status" `
  -Actual $response.provider_status `
  -Expected "failed"

Assert-Equal -Name "provider failure response error code" `
  -Actual $response.provider_error_code `
  -Expected "provider_model_missing"

Assert-Equal -Name "provider failure response error message" `
  -Actual $response.provider_error_message `
  -Expected "Provider model is not available locally: $ExpectedMissingModel"

$artifactId = $response.artifact_id

$artifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$artifactId" `
  -Method Get

$artifactResponseJson = $artifactResponse | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $artifactResponseJson

if ($null -eq $artifactResponse.artifact) {
  throw "Missing artifact object in artifact retrieval response."
}

Assert-Equal -Name "artifact failure status" `
  -Actual $artifactResponse.artifact.status `
  -Expected "provider_failed"

Assert-Equal -Name "artifact failure provider backend" `
  -Actual $artifactResponse.artifact.provider_backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "artifact failure provider model" `
  -Actual $artifactResponse.artifact.provider_model `
  -Expected $ExpectedMissingModel

Assert-Equal -Name "artifact failure provider status" `
  -Actual $artifactResponse.artifact.provider_status `
  -Expected "failed"

Assert-Equal -Name "artifact failure provider error code" `
  -Actual $artifactResponse.artifact.provider_error_code `
  -Expected "provider_model_missing"

Assert-Equal -Name "artifact failure provider error message" `
  -Actual $artifactResponse.artifact.provider_error_message `
  -Expected "Provider model is not available locally: $ExpectedMissingModel"

$lineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$artifactId" `
  -Method Get

$lineageResponseJson = $lineageResponse | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $lineageResponseJson

if ($null -eq $lineageResponse.lineage) {
  throw "Missing lineage object in lineage retrieval response."
}

Assert-Equal -Name "lineage failure status" `
  -Actual $lineageResponse.lineage.artifact_status `
  -Expected "provider_failed"

Assert-Equal -Name "lineage failure provider backend" `
  -Actual $lineageResponse.lineage.artifact_provider_backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "lineage failure provider model" `
  -Actual $lineageResponse.lineage.artifact_provider_model `
  -Expected $ExpectedMissingModel

Assert-Equal -Name "lineage failure provider status" `
  -Actual $lineageResponse.lineage.artifact_provider_status `
  -Expected "failed"

Assert-Equal -Name "lineage failure provider error code" `
  -Actual $lineageResponse.lineage.artifact_provider_error_code `
  -Expected "provider_model_missing"

Assert-Equal -Name "lineage failure provider error message" `
  -Actual $lineageResponse.lineage.artifact_provider_error_message `
  -Expected "Provider model is not available locally: $ExpectedMissingModel"

Write-Host "Provider failure surface integration test passed." -ForegroundColor Green
