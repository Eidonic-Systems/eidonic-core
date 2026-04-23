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

function Get-DefaultSourceForSignalType {
    param(
        [string]$SignalType
    )

    switch ($SignalType) {
        'user_message' { return 'chat' }
        'command' { return 'api' }
        'system_event' { return 'internal' }
        default { return 'api' }
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$governanceManifestPath = Join-Path $resolvedRepoRoot 'config\governance_rules_manifest.json'
$fixturePath = Join-Path $resolvedRepoRoot 'tests\fixtures\governance_rule_fixtures.json'

if (-not (Test-Path $governanceManifestPath)) {
    throw "Missing governance rules manifest at $governanceManifestPath"
}

if (-not (Test-Path $fixturePath)) {
    throw "Missing governance fixture file at $fixturePath"
}

$governanceManifest = Get-Content $governanceManifestPath -Raw | ConvertFrom-Json
$fixtureSet = Get-Content $fixturePath -Raw | ConvertFrom-Json

if ([string]$governanceManifest.manifest_version -ne [string]$fixtureSet.manifest_version) {
    throw "Fixture manifest_version does not match governance manifest_version."
}

$defaultSuccess = $governanceManifest.default_success
$expectedGovernanceOutcome = [string]$defaultSuccess.governance_outcome
$expectedGovernanceReason = [string]$defaultSuccess.governance_reason
$expectedGovernanceRuleId = [string]$defaultSuccess.rule_id
$expectedGovernanceManifestVersion = [string]$governanceManifest.manifest_version

$enabledRules = @($governanceManifest.rules | Where-Object { [bool]$_.enabled })
$negativeFixtures = @($fixtureSet.fixtures | Where-Object { -not [bool]$_.should_match })

if ($enabledRules.Count -eq 0) {
    throw "Governance manifest has no enabled rules."
}

if ($negativeFixtures.Count -eq 0) {
    throw "Governance fixture file has no negative fixtures."
}

if ($negativeFixtures.Count -ne $enabledRules.Count) {
    throw ("Negative fixture count '{0}' did not match enabled rule count '{1}'." -f $negativeFixtures.Count, $enabledRules.Count)
}

$ruleMap = @{}
foreach ($rule in $enabledRules) {
    $ruleMap[[string]$rule.rule_id] = $rule
}

Write-Host ""
Write-Host "Governance negative matrix provenance invariant validation:" -ForegroundColor Yellow
Write-Host ("  base url: {0}" -f $EidonBaseUrl)
Write-Host ("  manifest version: {0}" -f $expectedGovernanceManifestVersion)
Write-Host ("  negative fixture count: {0}" -f $negativeFixtures.Count)

$health = Invoke-RestMethod -Uri "$EidonBaseUrl/health" -Method Get

Write-Host ""
Write-Host "Baseline health payload:" -ForegroundColor Yellow
Write-Host ($health | ConvertTo-Json -Depth 12)

$warmResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" -Method Post

Write-Host ""
Write-Host "Baseline warm payload:" -ForegroundColor Yellow
Write-Host ($warmResponse | ConvertTo-Json -Depth 12)

$failures = [System.Collections.ArrayList]::new()
$caseResults = [System.Collections.ArrayList]::new()

if ([string]$health.status -ne 'ok') {
    Add-Failure -Failures $failures -Message ("baseline health.status was '{0}', not 'ok'" -f [string]$health.status)
}

if ([string]$health.artifact_store.status -ne 'ok') {
    Add-Failure -Failures $failures -Message ("baseline artifact_store.status was '{0}', not 'ok'" -f [string]$health.artifact_store.status)
}

if ([string]$health.lineage_store.status -ne 'ok') {
    Add-Failure -Failures $failures -Message ("baseline lineage_store.status was '{0}', not 'ok'" -f [string]$health.lineage_store.status)
}

if ([string]$warmResponse.status -ne 'warmed') {
    Add-Failure -Failures $failures -Message ("baseline warm status was '{0}', not 'warmed'" -f [string]$warmResponse.status)
}

$index = 0

foreach ($fixture in $negativeFixtures) {
    $index += 1

    $fixtureId = [string]$fixture.fixture_id
    $signalType = [string]$fixture.signal_type
    $fixtureText = [string]$fixture.text

    if (-not $fixtureId.StartsWith('negative_')) {
        Add-Failure -Failures $failures -Message ("negative fixture id did not start with 'negative_': {0}" -f $fixtureId)
        continue
    }

    $targetRuleId = $fixtureId.Substring('negative_'.Length)
    if (-not $ruleMap.ContainsKey($targetRuleId)) {
        Add-Failure -Failures $failures -Message ("negative fixture '{0}' did not map to an enabled rule id" -f $fixtureId)
        continue
    }

    $targetRule = $ruleMap[$targetRuleId]
    $targetRuleOutcome = [string]$targetRule.governance_outcome
    $targetRuleReason = [string]$targetRule.governance_reason

    $stamp = Get-Date -Format 'yyyyMMddHHmmssfff'
    $sessionId = "session-governance-negative-$index-$stamp"
    $signalId = "sig-governance-negative-$index-$stamp"

    $payload = [ordered]@{
        session_id = $sessionId
        signal_id = $signalId
        signal_type = $signalType
        source = (Get-DefaultSourceForSignalType -SignalType $signalType)
        threshold_result = 'pass'
        intent = 'status_summary'
        content = [ordered]@{
            text = $fixtureText
        }
    }

    Write-Host ""
    Write-Host ("Governance negative matrix payload [{0}] against {1}:" -f $fixtureId, $targetRuleId) -ForegroundColor Yellow
    Write-Host ($payload | ConvertTo-Json -Depth 8)

    $orchestrateResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 8)

    Write-Host ""
    Write-Host ("Governance negative matrix orchestration response [{0}]:" -f $fixtureId) -ForegroundColor Yellow
    Write-Host ($orchestrateResponse | ConvertTo-Json -Depth 12)

    $artifactId = [string]$orchestrateResponse.artifact_id
    if ([string]::IsNullOrWhiteSpace($artifactId)) {
        Add-Failure -Failures $failures -Message ("orchestration response for negative fixture '{0}' did not include an artifact_id" -f $fixtureId)
        continue
    }

    $lineageId = [string]$orchestrateResponse.lineage_id
    if ([string]::IsNullOrWhiteSpace($lineageId)) {
        Add-Failure -Failures $failures -Message ("orchestration response for negative fixture '{0}' did not include a lineage_id" -f $fixtureId)
        continue
    }

    $artifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$artifactId" -Method Get
    $lineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$artifactId" -Method Get

    Write-Host ""
    Write-Host ("Governance negative matrix artifact retrieval [{0}]:" -f $fixtureId) -ForegroundColor Yellow
    Write-Host ($artifactResponse | ConvertTo-Json -Depth 12)

    Write-Host ""
    Write-Host ("Governance negative matrix lineage retrieval [{0}]:" -f $fixtureId) -ForegroundColor Yellow
    Write-Host ($lineageResponse | ConvertTo-Json -Depth 12)

    $artifact = $artifactResponse.artifact
    $lineage = $lineageResponse.lineage

    if ([string]$orchestrateResponse.status -ne 'orchestrated') {
        Add-Failure -Failures $failures -Message ("orchestration response status for negative fixture '{0}' was '{1}', not 'orchestrated'" -f $fixtureId, [string]$orchestrateResponse.status)
    }

    if ([string]$artifactResponse.status -ne 'found') {
        Add-Failure -Failures $failures -Message ("artifact retrieval status for negative fixture '{0}' was '{1}', not 'found'" -f $fixtureId, [string]$artifactResponse.status)
    }

    if ([string]$lineageResponse.status -ne 'found') {
        Add-Failure -Failures $failures -Message ("lineage retrieval status for negative fixture '{0}' was '{1}', not 'found'" -f $fixtureId, [string]$lineageResponse.status)
    }

    if ($null -eq $artifact) {
        Add-Failure -Failures $failures -Message ("artifact retrieval response was missing artifact data for negative fixture '{0}'" -f $fixtureId)
        continue
    }

    if ($null -eq $lineage) {
        Add-Failure -Failures $failures -Message ("lineage retrieval response was missing lineage data for negative fixture '{0}'" -f $fixtureId)
        continue
    }

    Assert-EqualValue -Label ("[{0}] artifact_id" -f $fixtureId) -Expected $artifactId -Actual $artifact.artifact_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage_id" -f $fixtureId) -Expected $lineageId -Actual $lineage.lineage_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] session_id" -f $fixtureId) -Expected $sessionId -Actual $artifact.session_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.session_id" -f $fixtureId) -Expected $sessionId -Actual $lineage.session_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] signal_id" -f $fixtureId) -Expected $signalId -Actual $artifact.signal_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.signal_id" -f $fixtureId) -Expected $signalId -Actual $lineage.signal_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] signal_type" -f $fixtureId) -Expected $signalType -Actual $artifact.signal_type -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.signal_type" -f $fixtureId) -Expected $signalType -Actual $lineage.signal_type -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.status" -f $fixtureId) -Expected 'orchestrated' -Actual $artifact.status -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.artifact_status" -f $fixtureId) -Expected $artifact.status -Actual $lineage.artifact_status -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.storage_backend vs lineage.artifact_storage_backend" -f $fixtureId) -Expected $artifact.storage_backend -Actual $lineage.artifact_storage_backend -Failures $failures

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

        Assert-EqualValue -Label ("[{0}] artifact.{1} vs lineage.artifact_{1}" -f $fixtureId, $field) -Expected $artifactValue -Actual $lineageValue -Failures $failures
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

        Assert-EqualValue -Label ("[{0}] orchestration response {1} vs artifact.{1}" -f $fixtureId, $field) -Expected $responseValue -Actual $artifactValue -Failures $failures
    }

    Assert-EqualValue -Label ("[{0}] artifact.governance_outcome" -f $fixtureId) -Expected $expectedGovernanceOutcome -Actual $artifact.governance_outcome -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.governance_reason" -f $fixtureId) -Expected $expectedGovernanceReason -Actual $artifact.governance_reason -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.governance_rule_id" -f $fixtureId) -Expected $expectedGovernanceRuleId -Actual $artifact.governance_rule_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.governance_manifest_version" -f $fixtureId) -Expected $expectedGovernanceManifestVersion -Actual $artifact.governance_manifest_version -Failures $failures

    Assert-EqualValue -Label ("[{0}] artifact.provider_status" -f $fixtureId) -Expected 'succeeded' -Actual $artifact.provider_status -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_route_mode" -f $fixtureId) -Expected 'control' -Actual $artifact.provider_route_mode -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_error_code" -f $fixtureId) -Expected '' -Actual $artifact.provider_error_code -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_error_message" -f $fixtureId) -Expected '' -Actual $artifact.provider_error_message -Failures $failures

    if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_route_reason)) {
        Add-Failure -Failures $failures -Message ("artifact.provider_route_reason was empty for negative fixture '{0}'" -f $fixtureId)
    }

    if ([string]$artifact.governance_outcome -eq $targetRuleOutcome) {
        Add-Failure -Failures $failures -Message ("negative fixture '{0}' incorrectly persisted target rule governance_outcome '{1}'" -f $fixtureId, $targetRuleOutcome)
    }

    if ([string]$artifact.governance_reason -eq $targetRuleReason) {
        Add-Failure -Failures $failures -Message ("negative fixture '{0}' incorrectly persisted target rule governance_reason '{1}'" -f $fixtureId, $targetRuleReason)
    }

    if ([string]$artifact.governance_rule_id -eq $targetRuleId) {
        Add-Failure -Failures $failures -Message ("negative fixture '{0}' incorrectly persisted target rule id '{1}'" -f $fixtureId, $targetRuleId)
    }

    [void]$caseResults.Add([pscustomobject]@{
        fixture_id = $fixtureId
        target_rule_id = $targetRuleId
        signal_type = $signalType
        governance_outcome = [string]$artifact.governance_outcome
        governance_reason = [string]$artifact.governance_reason
        governance_rule_id = [string]$artifact.governance_rule_id
        governance_manifest_version = [string]$artifact.governance_manifest_version
        provider_status = [string]$artifact.provider_status
        provider_route_mode = [string]$artifact.provider_route_mode
        provider_route_reason = [string]$artifact.provider_route_reason
        artifact_id = [string]$artifact.artifact_id
        lineage_id = [string]$lineage.lineage_id
    })
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { 'passed' } else { 'failed' })
    manifest_version = $expectedGovernanceManifestVersion
    negative_fixture_count = $negativeFixtures.Count
    expected_default_success_rule_id = $expectedGovernanceRuleId
    case_results = @($caseResults)
    failures = @($failures)
}

Write-Host ""
Write-Host "Governance negative matrix provenance invariant validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne 'passed') {
    throw "Governance negative matrix provenance invariant validation failed."
}

Write-Host ""
Write-Host "Governance negative matrix provenance invariant validation passed." -ForegroundColor Green

