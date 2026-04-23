param(
    [string]$RepoRoot = ".",
    [int]$Port = 8016
)

$ErrorActionPreference = "Stop"

function Add-Failure {
    param(
        [System.Collections.ArrayList]$Failures,
        [string]$Message
    )

    [void]$Failures.Add($Message)
}

function Get-EnvMap {
    param([string]$EnvPath)

    $map = @{}

    foreach ($line in Get-Content $EnvPath) {
        $trimmed = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed.StartsWith("#")) { continue }
        if ($trimmed -notmatch '^[A-Za-z_][A-Za-z0-9_]*=') { continue }

        $parts = $trimmed -split '=', 2
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()

        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $map[$key] = $value
    }

    return $map
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

function Wait-For-Health {
    param(
        [string]$BaseUrl,
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -TimeoutSec 5
            if ($null -ne $response.status -and [string]$response.status -eq 'ok') {
                return $response
            }
        }
        catch {
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "Temporary routing-control Orchestrator did not become reachable at $BaseUrl/health."
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$envPath = Join-Path $resolvedRepoRoot '.env'
$orchestratorRoot = Join-Path $resolvedRepoRoot 'services\eidon-orchestrator'
$orchestratorPython = Join-Path $orchestratorRoot '.venv\Scripts\python.exe'
$governanceManifestPath = Join-Path $resolvedRepoRoot 'config\governance_rules_manifest.json'
$baseUrl = "http://127.0.0.1:$Port"

if (-not (Test-Path $envPath)) {
    throw "Missing .env at $envPath"
}

if (-not (Test-Path $orchestratorPython)) {
    throw "Missing Orchestrator Python executable at $orchestratorPython"
}

if (-not (Test-Path $governanceManifestPath)) {
    throw "Missing governance rules manifest at $governanceManifestPath"
}

$envMap = Get-EnvMap -EnvPath $envPath
$configuredBackend = [string]$envMap['EIDON_PROVIDER_BACKEND']
$configuredControlModel = [string]$envMap['EIDON_PROVIDER_MODEL']
$configuredCandidateModel = [string]$envMap['EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL']

if ([string]::IsNullOrWhiteSpace($configuredBackend)) {
    $configuredBackend = 'ollama'
}

if ([string]::IsNullOrWhiteSpace($configuredControlModel)) {
    throw "EIDON_PROVIDER_MODEL must be set in .env for routing control-nonrouteable validation."
}

if ([string]::IsNullOrWhiteSpace($configuredCandidateModel)) {
    throw "EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL must be set in .env for routing control-nonrouteable validation."
}

if ($configuredCandidateModel -eq $configuredControlModel) {
    throw "EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL must differ from EIDON_PROVIDER_MODEL for routing control-nonrouteable validation."
}

if ($configuredBackend -ne 'ollama') {
    throw "Routing control-nonrouteable validation requires EIDON_PROVIDER_BACKEND=ollama."
}

$governanceManifest = Get-Content $governanceManifestPath -Raw | ConvertFrom-Json
$defaultSuccess = $governanceManifest.default_success
$expectedGovernanceOutcome = [string]$defaultSuccess.governance_outcome
$expectedGovernanceReason = [string]$defaultSuccess.governance_reason
$expectedGovernanceRuleId = [string]$defaultSuccess.rule_id
$expectedGovernanceManifestVersion = [string]$governanceManifest.manifest_version

Write-Host ""
Write-Host "Routing control nonrouteable provenance invariant validation:" -ForegroundColor Yellow
Write-Host ("  repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("  temporary base url: {0}" -f $baseUrl)
Write-Host ("  control backend: {0}" -f $configuredBackend)
Write-Host ("  control model: {0}" -f $configuredControlModel)
Write-Host ("  candidate model: {0}" -f $configuredCandidateModel)

$overrides = [ordered]@{
    EIDON_PROVIDER_BACKEND = $configuredBackend
    EIDON_PROVIDER_MODEL = $configuredControlModel
    EIDON_DOMAIN_ROUTING_ENABLED = 'true'
    EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL = $configuredCandidateModel
}

$originalEnv = @{}
foreach ($key in $overrides.Keys) {
    if (Test-Path ("Env:{0}" -f $key)) {
        $originalEnv[$key] = (Get-Item ("Env:{0}" -f $key)).Value
    }
    Set-Item -Path ("Env:{0}" -f $key) -Value ([string]$overrides[$key])
}

$process = $null

try {
    $process = Start-Process -FilePath $orchestratorPython `
        -ArgumentList @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', [string]$Port) `
        -WorkingDirectory $orchestratorRoot `
        -PassThru

    $baselineHealth = Wait-For-Health -BaseUrl $baseUrl

    Write-Host ""
    Write-Host "Temporary routing-control baseline health payload:" -ForegroundColor Yellow
    Write-Host ($baselineHealth | ConvertTo-Json -Depth 12)

    $warmResponse = Invoke-RestMethod -Uri "$baseUrl/provider/warm" -Method Post

    Write-Host ""
    Write-Host "Routing-control warm payload:" -ForegroundColor Yellow
    Write-Host ($warmResponse | ConvertTo-Json -Depth 12)

    $postWarmHealth = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get

    Write-Host ""
    Write-Host "Routing-control post-warm health payload:" -ForegroundColor Yellow
    Write-Host ($postWarmHealth | ConvertTo-Json -Depth 12)

    $stamp = Get-Date -Format 'yyyyMMddHHmmssfff'
    $sessionId = "session-routing-control-$stamp"
    $signalId = "sig-routing-control-$stamp"

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
    Write-Host "Routing-control orchestration payload:" -ForegroundColor Yellow
    Write-Host ($payload | ConvertTo-Json -Depth 8)

    $orchestrateResponse = Invoke-RestMethod -Uri "$baseUrl/orchestrate" -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 8)

    Write-Host ""
    Write-Host "Routing-control orchestration response:" -ForegroundColor Yellow
    Write-Host ($orchestrateResponse | ConvertTo-Json -Depth 12)

    $artifactId = [string]$orchestrateResponse.artifact_id
    if ([string]::IsNullOrWhiteSpace($artifactId)) {
        throw "Routing-control orchestration response did not include an artifact_id."
    }

    $lineageId = [string]$orchestrateResponse.lineage_id
    if ([string]::IsNullOrWhiteSpace($lineageId)) {
        throw "Routing-control orchestration response did not include a lineage_id."
    }

    $artifactResponse = Invoke-RestMethod -Uri "$baseUrl/artifacts/$artifactId" -Method Get
    $lineageResponse = Invoke-RestMethod -Uri "$baseUrl/lineage/$artifactId" -Method Get

    Write-Host ""
    Write-Host "Routing-control artifact retrieval response:" -ForegroundColor Yellow
    Write-Host ($artifactResponse | ConvertTo-Json -Depth 12)

    Write-Host ""
    Write-Host "Routing-control lineage retrieval response:" -ForegroundColor Yellow
    Write-Host ($lineageResponse | ConvertTo-Json -Depth 12)

    $artifact = $artifactResponse.artifact
    $lineage = $lineageResponse.lineage

    $failures = [System.Collections.ArrayList]::new()

    if ([string]$baselineHealth.status -ne 'ok') {
        Add-Failure -Failures $failures -Message ("baseline health.status was '{0}', not 'ok'" -f [string]$baselineHealth.status)
    }

    if ([string]$baselineHealth.artifact_store.status -ne 'ok') {
        Add-Failure -Failures $failures -Message ("baseline artifact_store.status was '{0}', not 'ok'" -f [string]$baselineHealth.artifact_store.status)
    }

    if ([string]$baselineHealth.lineage_store.status -ne 'ok') {
        Add-Failure -Failures $failures -Message ("baseline lineage_store.status was '{0}', not 'ok'" -f [string]$baselineHealth.lineage_store.status)
    }

    Assert-EqualValue -Label 'baseline provider.routing_enabled' -Expected 'True' -Actual ([string](Get-OptionalProperty -Object $baselineHealth.provider -Name 'routing_enabled')) -Failures $failures
    Assert-EqualValue -Label 'baseline provider.route_candidate_model' -Expected $configuredCandidateModel -Actual (Get-OptionalProperty -Object $baselineHealth.provider -Name 'route_candidate_model') -Failures $failures
    Assert-EqualValue -Label 'baseline provider.route_candidate_status' -Expected 'ok' -Actual (Get-OptionalProperty -Object $baselineHealth.provider -Name 'route_candidate_status') -Failures $failures

    if ([string]$warmResponse.status -ne 'warmed') {
        Add-Failure -Failures $failures -Message ("warm response status was '{0}', not 'warmed'" -f [string]$warmResponse.status)
    }

    if ($null -eq $warmResponse.provider) {
        Add-Failure -Failures $failures -Message 'warm response was missing provider details'
    }
    else {
        if (-not [bool]$warmResponse.provider.ready) {
            Add-Failure -Failures $failures -Message 'warm response did not report provider.ready=true'
        }

        Assert-EqualValue -Label 'warm provider.route_candidate_model' -Expected $configuredCandidateModel -Actual (Get-OptionalProperty -Object $warmResponse.provider -Name 'route_candidate_model') -Failures $failures
        Assert-EqualValue -Label 'warm provider.route_candidate_status' -Expected 'warmed' -Actual (Get-OptionalProperty -Object $warmResponse.provider -Name 'route_candidate_status') -Failures $failures
    }

    Assert-EqualValue -Label 'post-warm provider.route_candidate_model' -Expected $configuredCandidateModel -Actual (Get-OptionalProperty -Object $postWarmHealth.provider -Name 'route_candidate_model') -Failures $failures
    Assert-EqualValue -Label 'post-warm provider.route_candidate_status' -Expected 'ok' -Actual (Get-OptionalProperty -Object $postWarmHealth.provider -Name 'route_candidate_status') -Failures $failures

    if (-not [bool](Get-OptionalProperty -Object $postWarmHealth.provider -Name 'route_candidate_ready')) {
        Add-Failure -Failures $failures -Message 'post-warm provider.route_candidate_ready was not true'
    }

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
        Add-Failure -Failures $failures -Message 'artifact retrieval response was missing artifact data'
    }

    if ($null -eq $lineage) {
        Add-Failure -Failures $failures -Message 'lineage retrieval response was missing lineage data'
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

        Assert-EqualValue -Label 'artifact.provider_backend' -Expected $configuredBackend -Actual $artifact.provider_backend -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_model' -Expected $configuredControlModel -Actual $artifact.provider_model -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_status' -Expected 'succeeded' -Actual $artifact.provider_status -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_route_mode' -Expected 'control' -Actual $artifact.provider_route_mode -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_route_reason' -Expected 'control_non_routeable' -Actual $artifact.provider_route_reason -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_error_code' -Expected '' -Actual $artifact.provider_error_code -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_error_message' -Expected '' -Actual $artifact.provider_error_message -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_outcome' -Expected $expectedGovernanceOutcome -Actual $artifact.governance_outcome -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_reason' -Expected $expectedGovernanceReason -Actual $artifact.governance_reason -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_rule_id' -Expected $expectedGovernanceRuleId -Actual $artifact.governance_rule_id -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_manifest_version' -Expected $expectedGovernanceManifestVersion -Actual $artifact.governance_manifest_version -Failures $failures
    }

    $summary = [ordered]@{
        status = $(if ($failures.Count -eq 0) { 'passed' } else { 'failed' })
        temporary_base_url = $baseUrl
        control_backend = $configuredBackend
        control_model = $configuredControlModel
        candidate_model = $configuredCandidateModel
        artifact_id = $artifactId
        lineage_id = $lineageId
        provider_model = [string](Get-OptionalProperty -Object $artifact -Name 'provider_model')
        provider_route_mode = [string](Get-OptionalProperty -Object $artifact -Name 'provider_route_mode')
        provider_route_reason = [string](Get-OptionalProperty -Object $artifact -Name 'provider_route_reason')
        governance_outcome = [string](Get-OptionalProperty -Object $artifact -Name 'governance_outcome')
        governance_reason = [string](Get-OptionalProperty -Object $artifact -Name 'governance_reason')
        failures = @($failures)
    }

    Write-Host ""
    Write-Host "Routing control nonrouteable provenance invariant validation summary:" -ForegroundColor Yellow
    Write-Host ($summary | ConvertTo-Json -Depth 8)

    if ($summary.status -ne 'passed') {
        throw "Routing control nonrouteable provenance invariant validation failed."
    }

    Write-Host ""
    Write-Host "Routing control nonrouteable provenance invariant validation passed." -ForegroundColor Green
}
finally {
    if ($null -ne $process) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }

    foreach ($key in $overrides.Keys) {
        if ($originalEnv.ContainsKey($key)) {
            Set-Item -Path ("Env:{0}" -f $key) -Value $originalEnv[$key]
        }
        else {
            Remove-Item ("Env:{0}" -f $key) -ErrorAction SilentlyContinue
        }
    }
}
