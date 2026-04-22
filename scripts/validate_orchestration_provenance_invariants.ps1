param(
    [string]$RepoRoot = ".",
    [string]$EidonBaseUrl = "http://127.0.0.1:8003"
)

$ErrorActionPreference = "Stop"

function Add-Failure {
    param(
        [System.Collections.ArrayList]$Failures,
        [string]$Message
    )

    [void]$Failures.Add($Message)
}

function Get-OptionalProperty {
    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object.PSObject.Properties.Name -contains $Name) {
        return $Object.$Name
    }

    return $null
}

function Assert-EqualValue {
    param(
        [string]$Label,
        [object]$Expected,
        [object]$Actual,
        [System.Collections.ArrayList]$Failures
    )

    $expectedText = [string]$Expected
    $actualText = [string]$Actual

    if ($expectedText -ne $actualText) {
        Add-Failure -Failures $Failures -Message ("{0} mismatch. Expected '{1}' but got '{2}'." -f $Label, $expectedText, $actualText)
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$governanceManifestPath = Join-Path $resolvedRepoRoot 'config\governance_rules_manifest.json'

if (-not (Test-Path $governanceManifestPath)) {
    throw "Missing governance rules manifest at $governanceManifestPath"
}

$governanceManifest = Get-Content $governanceManifestPath -Raw | ConvertFrom-Json
$defaultSuccess = $governanceManifest.default_success
$expectedGovernanceOutcome = [string]$defaultSuccess.governance_outcome
$expectedGovernanceReason = [string]$defaultSuccess.governance_reason
$expectedGovernanceRuleId = [string]$defaultSuccess.rule_id
$expectedGovernanceManifestVersion = [string]$governanceManifest.manifest_version

Write-Host ""
Write-Host "Orchestration provenance invariant validation:" -ForegroundColor Yellow
Write-Host ("  base url: {0}" -f $EidonBaseUrl)

$warmResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" -Method Post
if ([string]$warmResponse.status -ne 'warmed') {
    throw "Provider warmup failed before orchestration provenance validation."
}
if ($null -eq $warmResponse.provider -or -not [bool]$warmResponse.provider.ready) {
    throw "Provider warmup did not produce a ready provider before orchestration provenance validation."
}

$stamp = Get-Date -Format 'yyyyMMddHHmmssfff'
$sessionId = "session-provenance-$stamp"
$signalId = "sig-provenance-$stamp"

$payload = [ordered]@{
    session_id = $sessionId
    signal_id = $signalId
    signal_type = 'user_message'
    source = 'chat'
    threshold_result = 'pass'
    intent = 'status_summary'
    content = [ordered]@{
        text = 'Summarize the current build discipline in one sentence.'
    }
}

Write-Host ""
Write-Host "Orchestration payload:" -ForegroundColor Yellow
Write-Host ($payload | ConvertTo-Json -Depth 8)

$orchestrateResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 8)

Write-Host ""
Write-Host "Orchestration response:" -ForegroundColor Yellow
Write-Host ($orchestrateResponse | ConvertTo-Json -Depth 12)

$artifactId = [string]$orchestrateResponse.artifact_id
if ([string]::IsNullOrWhiteSpace($artifactId)) {
    throw "Orchestration response did not include an artifact_id."
}

$lineageId = [string]$orchestrateResponse.lineage_id
if ([string]::IsNullOrWhiteSpace($lineageId)) {
    throw "Orchestration response did not include a lineage_id."
}

$artifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$artifactId" -Method Get
$lineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$artifactId" -Method Get

Write-Host ""
Write-Host "Artifact retrieval response:" -ForegroundColor Yellow
Write-Host ($artifactResponse | ConvertTo-Json -Depth 12)

Write-Host ""
Write-Host "Lineage retrieval response:" -ForegroundColor Yellow
Write-Host ($lineageResponse | ConvertTo-Json -Depth 12)

$artifact = $artifactResponse.artifact
$lineage = $lineageResponse.lineage

$failures = [System.Collections.ArrayList]::new()

if ([string]$orchestrateResponse.status -ne 'orchestrated') {
    Add-Failure -Failures $failures -Message ("orchestration response status was '{0}', not 'orchestrated'" -f [string]$orchestrateResponse.status)
}

if ([string]$artifactResponse.status -ne 'found') {
    Add-Failure -Failures $failures -Message ("artifact retrieval status was '{0}', not 'found'" -f [string]$artifactResponse.status)
}

if ([string]$lineageResponse.status -ne 'found') {
    Add-Failure -Failures $failures -Message ("lineage retrieval status was '{0}', not 'found'" -f [string]$lineageResponse.status)
}

if ($null -eq $artifact) {
    Add-Failure -Failures $failures -Message "artifact retrieval response was missing artifact data"
}

if ($null -eq $lineage) {
    Add-Failure -Failures $failures -Message "lineage retrieval response was missing lineage data"
}

if ($null -ne $artifact -and $null -ne $lineage) {
    Assert-EqualValue -Label 'artifact_id' -Expected $artifactId -Actual $artifact.artifact_id -Failures $failures
    Assert-EqualValue -Label 'lineage_id' -Expected $lineageId -Actual $lineage.lineage_id -Failures $failures
    Assert-EqualValue -Label 'session_id' -Expected $sessionId -Actual $artifact.session_id -Failures $failures
    Assert-EqualValue -Label 'lineage.session_id' -Expected $sessionId -Actual $lineage.session_id -Failures $failures
    Assert-EqualValue -Label 'signal_id' -Expected $signalId -Actual $artifact.signal_id -Failures $failures
    Assert-EqualValue -Label 'lineage.signal_id' -Expected $signalId -Actual $lineage.signal_id -Failures $failures
    Assert-EqualValue -Label 'artifact.status' -Expected 'orchestrated' -Actual $artifact.status -Failures $failures
    Assert-EqualValue -Label 'lineage.artifact_status' -Expected $artifact.status -Actual $lineage.artifact_status -Failures $failures
    Assert-EqualValue -Label 'artifact.storage_backend vs lineage.artifact_storage_backend' -Expected $artifact.storage_backend -Actual $lineage.artifact_storage_backend -Failures $failures

    foreach ($field in @(
        'provider_backend',
        'provider_model',
        'provider_status',
        'provider_route_mode',
        'provider_route_reason',
        'provider_error_code',
        'provider_error_message',
        'governance_outcome',
        'governance_reason',
        'governance_rule_id',
        'governance_manifest_version'
    )) {
        $artifactValue = Get-OptionalProperty -Object $artifact -Name $field
        $lineageValue = Get-OptionalProperty -Object $lineage -Name ("artifact_{0}" -f $field)

        Assert-EqualValue -Label ("artifact.{0} vs lineage.artifact_{0}" -f $field) -Expected $artifactValue -Actual $lineageValue -Failures $failures
    }

    foreach ($field in @(
        'provider_backend',
        'provider_model',
        'provider_status',
        'provider_route_mode',
        'provider_route_reason'
    )) {
        $responseValue = Get-OptionalProperty -Object $orchestrateResponse -Name $field
        $artifactValue = Get-OptionalProperty -Object $artifact -Name $field

        Assert-EqualValue -Label ("orchestration response {0} vs artifact.{0}" -f $field) -Expected $responseValue -Actual $artifactValue -Failures $failures
    }

    Assert-EqualValue -Label 'artifact.provider_status' -Expected 'succeeded' -Actual $artifact.provider_status -Failures $failures
    Assert-EqualValue -Label 'artifact.governance_outcome' -Expected $expectedGovernanceOutcome -Actual $artifact.governance_outcome -Failures $failures
    Assert-EqualValue -Label 'artifact.governance_reason' -Expected $expectedGovernanceReason -Actual $artifact.governance_reason -Failures $failures
    Assert-EqualValue -Label 'artifact.governance_rule_id' -Expected $expectedGovernanceRuleId -Actual $artifact.governance_rule_id -Failures $failures
    Assert-EqualValue -Label 'artifact.governance_manifest_version' -Expected $expectedGovernanceManifestVersion -Actual $artifact.governance_manifest_version -Failures $failures

    if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_route_mode)) {
        Add-Failure -Failures $failures -Message "artifact.provider_route_mode was empty"
    }

    if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_route_reason)) {
        Add-Failure -Failures $failures -Message "artifact.provider_route_reason was empty"
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { 'passed' } else { 'failed' })
    session_id = $sessionId
    signal_id = $signalId
    artifact_id = $artifactId
    lineage_id = $lineageId
    provider_backend = [string](Get-OptionalProperty -Object $artifact -Name 'provider_backend')
    provider_model = [string](Get-OptionalProperty -Object $artifact -Name 'provider_model')
    provider_status = [string](Get-OptionalProperty -Object $artifact -Name 'provider_status')
    provider_route_mode = [string](Get-OptionalProperty -Object $artifact -Name 'provider_route_mode')
    provider_route_reason = [string](Get-OptionalProperty -Object $artifact -Name 'provider_route_reason')
    governance_outcome = [string](Get-OptionalProperty -Object $artifact -Name 'governance_outcome')
    governance_reason = [string](Get-OptionalProperty -Object $artifact -Name 'governance_reason')
    governance_rule_id = [string](Get-OptionalProperty -Object $artifact -Name 'governance_rule_id')
    governance_manifest_version = [string](Get-OptionalProperty -Object $artifact -Name 'governance_manifest_version')
    failures = @($failures)
}

Write-Host ""
Write-Host "Orchestration provenance invariant validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne 'passed') {
    throw "Orchestration provenance invariant validation failed."
}

Write-Host ""
Write-Host "Orchestration provenance invariant validation passed." -ForegroundColor Green
