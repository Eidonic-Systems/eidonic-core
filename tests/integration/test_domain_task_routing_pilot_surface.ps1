param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$ExpectedEligibleModel = "gemma3n:e2b",
    [string]$ExpectedControlModel = "gemma3n:e4b"
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
    session_id = "routing-pilot-session-001"
    signal_id = "routing-pilot-sig-001"
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

$eligibleArtifact = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($eligibleResponse.artifact_id)" -Method Get

Write-Host ""
Write-Host ($eligibleArtifact | ConvertTo-Json -Depth 12)

Assert-Equal -Name "eligible artifact status" `
    -Actual $eligibleArtifact.artifact.status `
    -Expected "orchestrated"

Assert-Equal -Name "eligible artifact provider backend" `
    -Actual $eligibleArtifact.artifact.provider_backend `
    -Expected "ollama"

Assert-Equal -Name "eligible artifact provider model" `
    -Actual $eligibleArtifact.artifact.provider_model `
    -Expected $ExpectedEligibleModel

$controlPayload = @{
    session_id = "routing-pilot-session-002"
    signal_id = "routing-pilot-sig-002"
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

$controlArtifact = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($controlResponse.artifact_id)" -Method Get

Write-Host ""
Write-Host ($controlArtifact | ConvertTo-Json -Depth 12)

Assert-Equal -Name "control artifact status" `
    -Actual $controlArtifact.artifact.status `
    -Expected "orchestrated"

Assert-Equal -Name "control artifact provider backend" `
    -Actual $controlArtifact.artifact.provider_backend `
    -Expected "ollama"

Assert-Equal -Name "control artifact provider model" `
    -Actual $controlArtifact.artifact.provider_model `
    -Expected $ExpectedControlModel

Write-Host "Domain task routing pilot surface integration test passed." -ForegroundColor Green
