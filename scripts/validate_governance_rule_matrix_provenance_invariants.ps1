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

$enabledRules = @($governanceManifest.rules | Where-Object { [bool]$_.enabled })
$positiveFixtures = @($fixtureSet.fixtures | Where-Object { [bool]$_.should_match })

if ($enabledRules.Count -eq 0) {
    throw "Governance manifest has no enabled rules to validate."
}

if ($positiveFixtures.Count -eq 0) {
    throw "Governance fixture file has no positive fixtures to validate."
}

$fixtureMap = @{}
foreach ($fixture in $positiveFixtures) {
    $ruleId = [string]$fixture.expected_rule_id
    if ([string]::IsNullOrWhiteSpace($ruleId)) {
        throw "Positive governance fixture is missing expected_rule_id."
    }

    if (-not $fixtureMap.ContainsKey($ruleId)) {
        $fixtureMap[$ruleId] = $fixture
    }
}

$missingFixtureRuleIds = @()
foreach ($rule in $enabledRules) {
    $ruleId = [string]$rule.rule_id
    if (-not $fixtureMap.ContainsKey($ruleId)) {
        $missingFixtureRuleIds += $ruleId
    }
}

if ($missingFixtureRuleIds.Count -gt 0) {
    throw ("Positive governance fixtures are missing for enabled rule ids: {0}" -f ($missingFixtureRuleIds -join ', '))
}

Write-Host ""
Write-Host "Governance rule matrix provenance invariant validation:" -ForegroundColor Yellow
Write-Host ("  base url: {0}" -f $EidonBaseUrl)
Write-Host ("  manifest version: {0}" -f [string]$governanceManifest.manifest_version)
Write-Host ("  enabled rule count: {0}" -f $enabledRules.Count)

$health = Invoke-RestMethod -Uri "$EidonBaseUrl/health" -Method Get

Write-Host ""
Write-Host "Baseline health payload:" -ForegroundColor Yellow
Write-Host ($health | ConvertTo-Json -Depth 12)

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

$index = 0

foreach ($rule in $enabledRules) {
    $index += 1

    $ruleId = [string]$rule.rule_id
    $expectedOutcome = [string]$rule.governance_outcome
    $expectedReason = [string]$rule.governance_reason
    $expectedResponseText = [string]$rule.response_text
    $expectedManifestVersion = [string]$governanceManifest.manifest_version

    $fixture = $fixtureMap[$ruleId]
    $fixtureId = [string]$fixture.fixture_id
    $signalType = [string]$fixture.signal_type
    $fixtureText = [string]$fixture.text
    $expectedFixtureOutcome = [string]$fixture.expected_governance_outcome

    if ($expectedFixtureOutcome -ne $expectedOutcome) {
        Add-Failure -Failures $failures -Message ("fixture outcome mismatch for rule '{0}'. Fixture expected '{1}' but manifest rule declares '{2}'." -f $ruleId, $expectedFixtureOutcome, $expectedOutcome)
        continue
    }

    $stamp = Get-Date -Format 'yyyyMMddHHmmssfff'
    $sessionId = "session-governance-matrix-$index-$stamp"
    $signalId = "sig-governance-matrix-$index-$stamp"

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
    Write-Host ("Governance matrix payload [{0}] {1}:" -f $fixtureId, $ruleId) -ForegroundColor Yellow
    Write-Host ($payload | ConvertTo-Json -Depth 8)

    $orchestrateResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 8)

    Write-Host ""
    Write-Host ("Governance matrix orchestration response [{0}] {1}:" -f $fixtureId, $ruleId) -ForegroundColor Yellow
    Write-Host ($orchestrateResponse | ConvertTo-Json -Depth 12)

    $artifactId = [string]$orchestrateResponse.artifact_id
    if ([string]::IsNullOrWhiteSpace($artifactId)) {
        Add-Failure -Failures $failures -Message ("orchestration response for rule '{0}' did not include an artifact_id" -f $ruleId)
        continue
    }

    $lineageId = [string]$orchestrateResponse.lineage_id
    if ([string]::IsNullOrWhiteSpace($lineageId)) {
        Add-Failure -Failures $failures -Message ("orchestration response for rule '{0}' did not include a lineage_id" -f $ruleId)
        continue
    }

    $artifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$artifactId" -Method Get
    $lineageResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/lineage/$artifactId" -Method Get

    Write-Host ""
    Write-Host ("Governance matrix artifact retrieval [{0}] {1}:" -f $fixtureId, $ruleId) -ForegroundColor Yellow
    Write-Host ($artifactResponse | ConvertTo-Json -Depth 12)

    Write-Host ""
    Write-Host ("Governance matrix lineage retrieval [{0}] {1}:" -f $fixtureId, $ruleId) -ForegroundColor Yellow
    Write-Host ($lineageResponse | ConvertTo-Json -Depth 12)

    $artifact = $artifactResponse.artifact
    $lineage = $lineageResponse.lineage

    if ([string]$orchestrateResponse.status -ne 'orchestrated') {
        Add-Failure -Failures $failures -Message ("orchestration response status for rule '{0}' was '{1}', not 'orchestrated'" -f $ruleId, [string]$orchestrateResponse.status)
    }

    if ([string]$artifactResponse.status -ne 'found') {
        Add-Failure -Failures $failures -Message ("artifact retrieval status for rule '{0}' was '{1}', not 'found'" -f $ruleId, [string]$artifactResponse.status)
    }

    if ([string]$lineageResponse.status -ne 'found') {
        Add-Failure -Failures $failures -Message ("lineage retrieval status for rule '{0}' was '{1}', not 'found'" -f $ruleId, [string]$lineageResponse.status)
    }

    if ($null -eq $artifact) {
        Add-Failure -Failures $failures -Message ("artifact retrieval response was missing artifact data for rule '{0}'" -f $ruleId)
        continue
    }

    if ($null -eq $lineage) {
        Add-Failure -Failures $failures -Message ("lineage retrieval response was missing lineage data for rule '{0}'" -f $ruleId)
        continue
    }

    Assert-EqualValue -Label ("[{0}] artifact_id" -f $ruleId) -Expected $artifactId -Actual $artifact.artifact_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage_id" -f $ruleId) -Expected $lineageId -Actual $lineage.lineage_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] session_id" -f $ruleId) -Expected $sessionId -Actual $artifact.session_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.session_id" -f $ruleId) -Expected $sessionId -Actual $lineage.session_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] signal_id" -f $ruleId) -Expected $signalId -Actual $artifact.signal_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.signal_id" -f $ruleId) -Expected $signalId -Actual $lineage.signal_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] signal_type" -f $ruleId) -Expected $signalType -Actual $artifact.signal_type -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.signal_type" -f $ruleId) -Expected $signalType -Actual $lineage.signal_type -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.status" -f $ruleId) -Expected 'orchestrated' -Actual $artifact.status -Failures $failures
    Assert-EqualValue -Label ("[{0}] lineage.artifact_status" -f $ruleId) -Expected $artifact.status -Actual $lineage.artifact_status -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.storage_backend vs lineage.artifact_storage_backend" -f $ruleId) -Expected $artifact.storage_backend -Actual $lineage.artifact_storage_backend -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.response_text" -f $ruleId) -Expected $expectedResponseText -Actual $artifact.response_text -Failures $failures

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

        Assert-EqualValue -Label ("[{0}] artifact.{1} vs lineage.artifact_{1}" -f $ruleId, $field) -Expected $artifactValue -Actual $lineageValue -Failures $failures
    }

    foreach ($field in @(
        'provider_backend',
        'provider_model',
        'provider_status',
        'provider_route_mode',
        'provider_route_reason',
        'governance_outcome',
        'governance_reason',
        'governance_rule_id',
        'governance_manifest_version'
    )) {
        $responseValue = Get-OptionalProperty -Object $orchestrateResponse -Name $field
        $artifactValue = Get-OptionalProperty -Object $artifact -Name $field

        Assert-EqualValue -Label ("[{0}] orchestration response {1} vs artifact.{1}" -f $ruleId, $field) -Expected $responseValue -Actual $artifactValue -Failures $failures
    }

    Assert-EqualValue -Label ("[{0}] artifact.governance_outcome" -f $ruleId) -Expected $expectedOutcome -Actual $artifact.governance_outcome -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.governance_reason" -f $ruleId) -Expected $expectedReason -Actual $artifact.governance_reason -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.governance_rule_id" -f $ruleId) -Expected $ruleId -Actual $artifact.governance_rule_id -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.governance_manifest_version" -f $ruleId) -Expected $expectedManifestVersion -Actual $artifact.governance_manifest_version -Failures $failures

    Assert-EqualValue -Label ("[{0}] artifact.provider_status" -f $ruleId) -Expected 'not_invoked' -Actual $artifact.provider_status -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_route_mode" -f $ruleId) -Expected 'control' -Actual $artifact.provider_route_mode -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_route_reason" -f $ruleId) -Expected 'control_default_no_routing' -Actual $artifact.provider_route_reason -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_error_code" -f $ruleId) -Expected '' -Actual $artifact.provider_error_code -Failures $failures
    Assert-EqualValue -Label ("[{0}] artifact.provider_error_message" -f $ruleId) -Expected '' -Actual $artifact.provider_error_message -Failures $failures

    if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_backend)) {
        Add-Failure -Failures $failures -Message ("artifact.provider_backend was empty for rule '{0}'" -f $ruleId)
    }

    if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_model)) {
        Add-Failure -Failures $failures -Message ("artifact.provider_model was empty for rule '{0}'" -f $ruleId)
    }

    [void]$caseResults.Add([pscustomobject]@{
        fixture_id = $fixtureId
        rule_id = $ruleId
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
    manifest_version = [string]$governanceManifest.manifest_version
    enabled_rule_count = $enabledRules.Count
    validated_rule_ids = @($enabledRules | ForEach-Object { [string]$_.rule_id })
    case_results = @($caseResults)
    failures = @($failures)
}

Write-Host ""
Write-Host "Governance rule matrix provenance invariant validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne 'passed') {
    throw "Governance rule matrix provenance invariant validation failed."
}

Write-Host ""
Write-Host "Governance rule matrix provenance invariant validation passed." -ForegroundColor Green

