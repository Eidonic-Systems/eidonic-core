param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$ExpectedManifestVersion = "phase-2-governance-pilot-v1"
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

# reshape
$reshapePayload = @{
    session_id = "gov-coverage-session-001"
    signal_id = "gov-coverage-sig-001"
    signal_type = "user_message"
    source = "chat"
    threshold_result = "pass"
    intent = "Respond to the user message."
    content = @{
        text = "I am rambling all over the place and need one next useful step."
    }
} | ConvertTo-Json -Depth 12

$reshapeResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $reshapePayload

$reshapeArtifact = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($reshapeResponse.artifact_id)" -Method Get
$reshapeLineage = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$($reshapeResponse.artifact_id)" -Method Get

Write-Host ""
Write-Host ($reshapeArtifact | ConvertTo-Json -Depth 12)
Write-Host ""
Write-Host ($reshapeLineage | ConvertTo-Json -Depth 12)

Assert-Equal -Name "reshape artifact governance outcome" -Actual $reshapeArtifact.artifact.governance_outcome -Expected "reshape"
Assert-Equal -Name "reshape artifact governance reason" -Actual $reshapeArtifact.artifact.governance_reason -Expected "scope_drift"
Assert-Equal -Name "reshape artifact governance rule id" -Actual $reshapeArtifact.artifact.governance_rule_id -Expected "reshape_scope_drift_request"
Assert-Equal -Name "reshape artifact manifest version" -Actual $reshapeArtifact.artifact.governance_manifest_version -Expected $ExpectedManifestVersion
Assert-Equal -Name "reshape artifact provider status" -Actual $reshapeArtifact.artifact.provider_status -Expected "not_invoked"
Assert-Equal -Name "reshape lineage governance outcome" -Actual $reshapeLineage.lineage.artifact_governance_outcome -Expected "reshape"
Assert-Equal -Name "reshape lineage governance reason" -Actual $reshapeLineage.lineage.artifact_governance_reason -Expected "scope_drift"
Assert-Equal -Name "reshape lineage governance rule id" -Actual $reshapeLineage.lineage.artifact_governance_rule_id -Expected "reshape_scope_drift_request"
Assert-Equal -Name "reshape lineage manifest version" -Actual $reshapeLineage.lineage.artifact_governance_manifest_version -Expected $ExpectedManifestVersion

# handoff
$handoffPayload = @{
    session_id = "gov-coverage-session-002"
    signal_id = "gov-coverage-sig-002"
    signal_type = "system_event"
    source = "internal"
    threshold_result = "pass"
    intent = "Interpret the system event."
    content = @{
        event = "human_review_recommended"
        reason = "material_accountability_needed"
    }
} | ConvertTo-Json -Depth 12

$handoffResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $handoffPayload

$handoffArtifact = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$($handoffResponse.artifact_id)" -Method Get
$handoffLineage = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$($handoffResponse.artifact_id)" -Method Get

Write-Host ""
Write-Host ($handoffArtifact | ConvertTo-Json -Depth 12)
Write-Host ""
Write-Host ($handoffLineage | ConvertTo-Json -Depth 12)

Assert-Equal -Name "handoff artifact governance outcome" -Actual $handoffArtifact.artifact.governance_outcome -Expected "handoff"
Assert-Equal -Name "handoff artifact governance reason" -Actual $handoffArtifact.artifact.governance_reason -Expected "human_review_required"
Assert-Equal -Name "handoff artifact governance rule id" -Actual $handoffArtifact.artifact.governance_rule_id -Expected "handoff_human_review_event"
Assert-Equal -Name "handoff artifact manifest version" -Actual $handoffArtifact.artifact.governance_manifest_version -Expected $ExpectedManifestVersion
Assert-Equal -Name "handoff artifact provider status" -Actual $handoffArtifact.artifact.provider_status -Expected "not_invoked"
Assert-Equal -Name "handoff lineage governance outcome" -Actual $handoffLineage.lineage.artifact_governance_outcome -Expected "handoff"
Assert-Equal -Name "handoff lineage governance reason" -Actual $handoffLineage.lineage.artifact_governance_reason -Expected "human_review_required"
Assert-Equal -Name "handoff lineage governance rule id" -Actual $handoffLineage.lineage.artifact_governance_rule_id -Expected "handoff_human_review_event"
Assert-Equal -Name "handoff lineage manifest version" -Actual $handoffLineage.lineage.artifact_governance_manifest_version -Expected $ExpectedManifestVersion

Write-Host "Governance outcome coverage surface integration test passed." -ForegroundColor Green
