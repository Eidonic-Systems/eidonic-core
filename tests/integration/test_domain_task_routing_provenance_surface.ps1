param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$ExpectedEligibleModel = "gemma3n:e2b",
    [string]$ExpectedEligibleRouteMode = "candidate",
    [string]$ExpectedEligibleRouteReason = "candidate_domain_route",
    [string]$ExpectedControlModel = "gemma3n:e4b",
    [string]$ExpectedControlRouteMode = "control",
    [string]$ExpectedControlRouteReason = "control_non_routeable"
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

$eligiblePayload = @{
    session_id = "routing-prov-session-001"
    signal_id = "routing-prov-sig-001"
    signal_type = "command"
    source = "api"
    threshold_result = "pass"
    intent = "Execute or respond to the command in the current session context."
    content = @{
        text = "Explain artifact lineage for the current session and what I should check next."
    }
} | ConvertTo-Json -Depth 12

$eligibleResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $eligiblePayload

$eligibleArtifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($eligibleResponse.artifact_id)" -Method Get
$eligibleLineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$($eligibleResponse.artifact_id)" -Method Get

Write-Host ""
Write-Host ($eligibleArtifactResponse | ConvertTo-Json -Depth 12)
Write-Host ""
Write-Host ($eligibleLineageResponse | ConvertTo-Json -Depth 12)

Assert-Equal -Name "eligible artifact provider model" `
    -Actual $eligibleArtifactResponse.artifact.provider_model `
    -Expected $ExpectedEligibleModel

Assert-Equal -Name "eligible artifact route mode" `
    -Actual $eligibleArtifactResponse.artifact.provider_route_mode `
    -Expected $ExpectedEligibleRouteMode

Assert-Equal -Name "eligible artifact route reason" `
    -Actual $eligibleArtifactResponse.artifact.provider_route_reason `
    -Expected $ExpectedEligibleRouteReason

Assert-Equal -Name "eligible lineage provider model" `
    -Actual $eligibleLineageResponse.lineage.artifact_provider_model `
    -Expected $ExpectedEligibleModel

Assert-Equal -Name "eligible lineage route mode" `
    -Actual $eligibleLineageResponse.lineage.artifact_provider_route_mode `
    -Expected $ExpectedEligibleRouteMode

Assert-Equal -Name "eligible lineage route reason" `
    -Actual $eligibleLineageResponse.lineage.artifact_provider_route_reason `
    -Expected $ExpectedEligibleRouteReason

$controlPayload = @{
    session_id = "routing-prov-session-002"
    signal_id = "routing-prov-sig-002"
    signal_type = "user_message"
    source = "chat"
    threshold_result = "pass"
    intent = "Respond to the user message: Hello there"
    content = @{
        text = "Hello there"
    }
} | ConvertTo-Json -Depth 12

$controlResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $controlPayload

$controlArtifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($controlResponse.artifact_id)" -Method Get
$controlLineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$($controlResponse.artifact_id)" -Method Get

Write-Host ""
Write-Host ($controlArtifactResponse | ConvertTo-Json -Depth 12)
Write-Host ""
Write-Host ($controlLineageResponse | ConvertTo-Json -Depth 12)

Assert-Equal -Name "control artifact provider model" `
    -Actual $controlArtifactResponse.artifact.provider_model `
    -Expected $ExpectedControlModel

Assert-Equal -Name "control artifact route mode" `
    -Actual $controlArtifactResponse.artifact.provider_route_mode `
    -Expected $ExpectedControlRouteMode

Assert-Equal -Name "control artifact route reason" `
    -Actual $controlArtifactResponse.artifact.provider_route_reason `
    -Expected $ExpectedControlRouteReason

Assert-Equal -Name "control lineage provider model" `
    -Actual $controlLineageResponse.lineage.artifact_provider_model `
    -Expected $ExpectedControlModel

Assert-Equal -Name "control lineage route mode" `
    -Actual $controlLineageResponse.lineage.artifact_provider_route_mode `
    -Expected $ExpectedControlRouteMode

Assert-Equal -Name "control lineage route reason" `
    -Actual $controlLineageResponse.lineage.artifact_provider_route_reason `
    -Expected $ExpectedControlRouteReason

Write-Host "Domain task routing provenance surface integration test passed." -ForegroundColor Green
