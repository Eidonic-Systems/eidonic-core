param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003"
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

$payload = @{
    session_id = "governance-prov-session-001"
    signal_id = "governance-prov-sig-001"
    signal_type = "user_message"
    source = "chat"
    threshold_result = "pass"
    intent = "Respond to the user message with a normal safe orchestration response."
    content = @{
        text = "The provider warmup passed. What is the next disciplined step?"
    }
} | ConvertTo-Json -Depth 12

$response = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $payload

$artifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($response.artifact_id)" -Method Get
$lineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$($response.artifact_id)" -Method Get

Write-Host ""
Write-Host ($artifactResponse | ConvertTo-Json -Depth 12)
Write-Host ""
Write-Host ($lineageResponse | ConvertTo-Json -Depth 12)

Assert-Equal -Name "artifact governance outcome" `
    -Actual $artifactResponse.artifact.governance_outcome `
    -Expected "allow"

Assert-Equal -Name "artifact governance reason" `
    -Actual $artifactResponse.artifact.governance_reason `
    -Expected "normal_orchestration_path"

Assert-Equal -Name "lineage governance outcome" `
    -Actual $lineageResponse.lineage.artifact_governance_outcome `
    -Expected "allow"

Assert-Equal -Name "lineage governance reason" `
    -Actual $lineageResponse.lineage.artifact_governance_reason `
    -Expected "normal_orchestration_path"

Write-Host "Governance provenance surface integration test passed." -ForegroundColor Green
