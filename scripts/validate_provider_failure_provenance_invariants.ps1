param(
    [string]$RepoRoot = ".",
    [int]$Port = 8013
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

function Wait-For-OrchestratorReachability {
    param(
        [string]$BaseUrl,
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri "$BaseUrl/artifacts?limit=1" -Method Get -TimeoutSec 5
            if (
                $null -ne $response.status -and
                [string]$response.status -eq 'found' -and
                [string]$response.service -eq 'eidon-orchestrator'
            ) {
                return $response
            }
        }
        catch {
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "Temporary failure-mode Orchestrator did not become reachable at $BaseUrl/artifacts?limit=1."
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$envPath = Join-Path $resolvedRepoRoot '.env'
$orchestratorRoot = Join-Path $resolvedRepoRoot 'services\eidon-orchestrator'
$orchestratorPython = Join-Path $orchestratorRoot '.venv\Scripts\python.exe'
$baseUrl = "http://127.0.0.1:$Port"

if (-not (Test-Path $envPath)) {
    throw "Missing .env at $envPath"
}

if (-not (Test-Path $orchestratorPython)) {
    throw "Missing Orchestrator Python executable at $orchestratorPython"
}

$envMap = Get-EnvMap -EnvPath $envPath
$configuredBackend = [string]$envMap['EIDON_PROVIDER_BACKEND']
if ([string]::IsNullOrWhiteSpace($configuredBackend)) {
    $configuredBackend = 'ollama'
}

$stamp = Get-Date -Format 'yyyyMMddHHmmssfff'
$missingModel = "phase2-missing-model-$stamp"

Write-Host ""
Write-Host "Provider failure provenance invariant validation:" -ForegroundColor Yellow
Write-Host ("  repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("  temporary base url: {0}" -f $baseUrl)
Write-Host ("  forced provider backend: {0}" -f $configuredBackend)
Write-Host ("  forced missing model: {0}" -f $missingModel)

$overrides = [ordered]@{
    EIDON_PROVIDER_BACKEND = $configuredBackend
    EIDON_PROVIDER_MODEL = $missingModel
    EIDON_DOMAIN_ROUTING_ENABLED = 'false'
    EIDON_DOMAIN_ROUTE_CANDIDATE_MODEL = ''
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

    $reachability = Wait-For-OrchestratorReachability -BaseUrl $baseUrl

    Write-Host ""
    Write-Host "Temporary failure-mode reachability payload:" -ForegroundColor Yellow
    Write-Host ($reachability | ConvertTo-Json -Depth 12)

    $warmResponse = Invoke-RestMethod -Uri "$baseUrl/provider/warm" -Method Post

    Write-Host ""
    Write-Host "Failure-mode warm payload:" -ForegroundColor Yellow
    Write-Host ($warmResponse | ConvertTo-Json -Depth 12)

    $sessionId = "session-provider-failure-$stamp"
    $signalId = "sig-provider-failure-$stamp"

    $payload = [ordered]@{
        session_id = $sessionId
        signal_id = $signalId
        signal_type = 'user_message'
        source = 'chat'
        threshold_result = 'pass'
        intent = 'status_summary'
        content = [ordered]@{
            text = 'Summarize the runtime discipline in one sentence.'
        }
    }

    Write-Host ""
    Write-Host "Failure-path orchestration payload:" -ForegroundColor Yellow
    Write-Host ($payload | ConvertTo-Json -Depth 8)

    $orchestrateResponse = Invoke-RestMethod -Uri "$baseUrl/orchestrate" -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 8)

    Write-Host ""
    Write-Host "Failure-path orchestration response:" -ForegroundColor Yellow
    Write-Host ($orchestrateResponse | ConvertTo-Json -Depth 12)

    $artifactId = [string]$orchestrateResponse.artifact_id
    if ([string]::IsNullOrWhiteSpace($artifactId)) {
        throw "Failure-path orchestration response did not include an artifact_id."
    }

    $lineageId = [string]$orchestrateResponse.lineage_id
    if ([string]::IsNullOrWhiteSpace($lineageId)) {
        throw "Failure-path orchestration response did not include a lineage_id."
    }

    $artifactResponse = Invoke-RestMethod -Uri "$baseUrl/artifacts/$artifactId" -Method Get
    $lineageResponse = Invoke-RestMethod -Uri "$baseUrl/lineage/$artifactId" -Method Get

    Write-Host ""
    Write-Host "Failure-path artifact retrieval response:" -ForegroundColor Yellow
    Write-Host ($artifactResponse | ConvertTo-Json -Depth 12)

    Write-Host ""
    Write-Host "Failure-path lineage retrieval response:" -ForegroundColor Yellow
    Write-Host ($lineageResponse | ConvertTo-Json -Depth 12)

    $artifact = $artifactResponse.artifact
    $lineage = $lineageResponse.lineage

    $failures = [System.Collections.ArrayList]::new()

    if ([string]$warmResponse.status -ne 'warm_failed') {
        Add-Failure -Failures $failures -Message ("warm response status was '{0}', not 'warm_failed'" -f [string]$warmResponse.status)
    }

    if ($null -eq $warmResponse.provider) {
        Add-Failure -Failures $failures -Message 'warm response was missing provider details'
    }
    else {
        if ([bool]$warmResponse.provider.ready) {
            Add-Failure -Failures $failures -Message 'warm response reported provider.ready=true during forced failure mode'
        }
    }

    Assert-EqualValue -Label 'warm provider_error_code' -Expected 'provider_model_missing' -Actual (Get-OptionalProperty -Object $warmResponse -Name 'provider_error_code') -Failures $failures

    if ([string]$orchestrateResponse.status -ne 'provider_failed') {
        Add-Failure -Failures $failures -Message ("orchestration response status was '{0}', not 'provider_failed'" -f [string]$orchestrateResponse.status)
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
        Assert-EqualValue -Label 'artifact.status' -Expected 'provider_failed' -Actual $artifact.status -Failures $failures
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
            'provider_route_reason',
            'provider_error_code',
            'provider_error_message',
            'governance_outcome',
            'governance_reason',
            'governance_rule_id',
            'governance_manifest_version'
        )) {
            $responseValue = Get-OptionalProperty -Object $orchestrateResponse -Name $field
            $artifactValue = Get-OptionalProperty -Object $artifact -Name $field

            Assert-EqualValue -Label ("orchestration response {0} vs artifact.{0}" -f $field) -Expected $responseValue -Actual $artifactValue -Failures $failures
        }

        Assert-EqualValue -Label 'artifact.provider_status' -Expected 'failed' -Actual $artifact.provider_status -Failures $failures
        Assert-EqualValue -Label 'artifact.provider_error_code' -Expected 'provider_model_missing' -Actual $artifact.provider_error_code -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_outcome' -Expected 'fallback' -Actual $artifact.governance_outcome -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_reason' -Expected 'provider_failure_recorded' -Actual $artifact.governance_reason -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_rule_id' -Expected '' -Actual $artifact.governance_rule_id -Failures $failures
        Assert-EqualValue -Label 'artifact.governance_manifest_version' -Expected '' -Actual $artifact.governance_manifest_version -Failures $failures

        if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_route_mode)) {
            Add-Failure -Failures $failures -Message 'artifact.provider_route_mode was empty on provider failure'
        }

        if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_route_reason)) {
            Add-Failure -Failures $failures -Message 'artifact.provider_route_reason was empty on provider failure'
        }

        if ([string]::IsNullOrWhiteSpace([string]$artifact.provider_error_message)) {
            Add-Failure -Failures $failures -Message 'artifact.provider_error_message was empty on provider failure'
        }
    }

    $summary = [ordered]@{
        status = $(if ($failures.Count -eq 0) { 'passed' } else { 'failed' })
        temporary_base_url = $baseUrl
        forced_backend = $configuredBackend
        forced_missing_model = $missingModel
        artifact_id = $artifactId
        lineage_id = $lineageId
        provider_status = [string](Get-OptionalProperty -Object $artifact -Name 'provider_status')
        provider_error_code = [string](Get-OptionalProperty -Object $artifact -Name 'provider_error_code')
        governance_outcome = [string](Get-OptionalProperty -Object $artifact -Name 'governance_outcome')
        governance_reason = [string](Get-OptionalProperty -Object $artifact -Name 'governance_reason')
        failures = @($failures)
    }

    Write-Host ""
    Write-Host "Provider failure provenance invariant validation summary:" -ForegroundColor Yellow
    Write-Host ($summary | ConvertTo-Json -Depth 8)

    if ($summary.status -ne 'passed') {
        throw "Provider failure provenance invariant validation failed."
    }

    Write-Host ""
    Write-Host "Provider failure provenance invariant validation passed." -ForegroundColor Green
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

