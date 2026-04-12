param(
    [string]$ControlModel = "gemma3n:e4b",
    [string]$CandidateModel = "gemma3n:e2b",
    [string]$ListenHost = "127.0.0.1",
    [int]$ControlPort = 8044,
    [int]$CandidatePort = 8045,
    [int]$ProviderTimeoutSeconds = 120,
    [string]$CasesPath = ".\evals\domain_task_eval_cases.json",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $RepoRoot ".env"
$OrchestratorDir = Join-Path $RepoRoot "services\eidon-orchestrator"
$PythonExe = Join-Path $OrchestratorDir ".venv\Scripts\python.exe"
$EvalScript = Join-Path $RepoRoot "scripts\run_domain_task_eval.ps1"
$ProfilesDir = Join-Path $RepoRoot "evals\profiles"

function Load-DotEnv {
    param(
        [string]$Path
    )

    $map = @{}

    if (-not (Test-Path $Path)) {
        return $map
    }

    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        if ($trimmed.StartsWith("#")) {
            continue
        }

        $parts = $trimmed.Split("=", 2)
        if ($parts.Count -ne 2) {
            continue
        }

        $key = $parts[0].Trim()
        $value = $parts[1].Trim()

        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $map[$key] = $value
        }
    }

    return $map
}

function Wait-For-Health {
    param(
        [string]$Url,
        [int]$MaxAttempts = 45,
        [int]$DelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
            if ($null -ne $response.status -and $response.status -eq "ok") {
                return
            }
        }
        catch {
        }

        Start-Sleep -Seconds $DelaySeconds
    }

    throw "Isolated Orchestrator health did not become ready at $Url."
}

function Sanitize-Label {
    param(
        [string]$Value
    )

    $sanitized = $Value.ToLowerInvariant() -replace '[^a-z0-9\-_.]+', '-'
    $sanitized = $sanitized.Trim('-')

    if ([string]::IsNullOrWhiteSpace($sanitized)) {
        return "model"
    }

    return $sanitized
}

function Run-IsolatedDomainProfile {
    param(
        [string]$ModelName,
        [int]$Port,
        [hashtable]$EnvMap,
        [string]$HostName,
        [int]$TimeoutSeconds,
        [string]$EvalCasesPath
    )

    $ollamaBaseUrl = if ($EnvMap.ContainsKey("OLLAMA_BASE_URL") -and -not [string]::IsNullOrWhiteSpace($EnvMap["OLLAMA_BASE_URL"])) {
        $EnvMap["OLLAMA_BASE_URL"]
    } else {
        "http://127.0.0.1:11434/api"
    }

    $warmKeepalive = if ($EnvMap.ContainsKey("EIDON_PROVIDER_WARM_KEEPALIVE") -and -not [string]::IsNullOrWhiteSpace($EnvMap["EIDON_PROVIDER_WARM_KEEPALIVE"])) {
        $EnvMap["EIDON_PROVIDER_WARM_KEEPALIVE"]
    } else {
        "15m"
    }

    $modelEscaped = $ModelName.Replace("'", "''")
    $ollamaBaseUrlEscaped = $ollamaBaseUrl.Replace("'", "''")
    $warmKeepaliveEscaped = $warmKeepalive.Replace("'", "''")
    $orchestratorDirEscaped = $OrchestratorDir.Replace("'", "''")
    $pythonExeEscaped = $PythonExe.Replace("'", "''")

    $command = @"
`$env:EIDON_PROVIDER_BACKEND = 'ollama'
`$env:EIDON_PROVIDER_MODEL = '$modelEscaped'
`$env:OLLAMA_BASE_URL = '$ollamaBaseUrlEscaped'
`$env:EIDON_PROVIDER_TIMEOUT_SECONDS = '$TimeoutSeconds'
`$env:EIDON_PROVIDER_WARM_KEEPALIVE = '$warmKeepaliveEscaped'
Set-Location '$orchestratorDirEscaped'
& '$pythonExeEscaped' -m uvicorn app.main:app --host $HostName --port $Port
"@

    $process = $null

    try {
        Write-Host ""
        Write-Host "Starting isolated domain runtime profile for model: $ModelName" -ForegroundColor Yellow

        $process = Start-Process powershell -ArgumentList @(
            '-ExecutionPolicy', 'Bypass',
            '-Command', $command
        ) -PassThru -WindowStyle Hidden

        Wait-For-Health -Url ("http://{0}:{1}/health" -f $HostName, $Port)

        $warmStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $warmResponse = Invoke-RestMethod -Uri ("http://{0}:{1}/provider/warm" -f $HostName, $Port) -Method Post
        $warmStopwatch.Stop()

        if ($warmResponse.status -ne "warmed") {
            throw "Warmup failed for model '$ModelName'. Status was '$($warmResponse.status)'."
        }

        if ($null -eq $warmResponse.provider -or $warmResponse.provider.model -ne $ModelName) {
            throw "Warmup model mismatch for '$ModelName'. Actual warm model was '$($warmResponse.provider.model)'."
        }

        $evalOutputPath = Join-Path $ProfilesDir ("domain_runtime_profile_eval_{0}.json" -f (Sanitize-Label -Value $ModelName))

        $evalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        (& powershell -ExecutionPolicy Bypass -File $EvalScript `
            -EidonBaseUrl ("http://{0}:{1}" -f $HostName, $Port) `
            -CasesPath $EvalCasesPath `
            -OutputPath $evalOutputPath) | Out-Host

        if ($LASTEXITCODE -ne 0) {
            throw "Domain eval run failed for model '$ModelName'."
        }

        $evalStopwatch.Stop()

        $evalResults = Get-Content $evalOutputPath -Raw | ConvertFrom-Json

        return [pscustomobject]@{
            model = $ModelName
            port = $Port
            warmup_ms = [math]::Round($warmStopwatch.Elapsed.TotalMilliseconds, 2)
            eval_duration_ms = [math]::Round($evalStopwatch.Elapsed.TotalMilliseconds, 2)
            total_profile_ms = [math]::Round(($warmStopwatch.Elapsed.TotalMilliseconds + $evalStopwatch.Elapsed.TotalMilliseconds), 2)
            eval_status = $evalResults.status
            passed_cases = $evalResults.passed_cases
            failed_cases = $evalResults.failed_cases
            results_path = $evalOutputPath
        }
    }
    finally {
        if ($null -ne $process -and -not $process.HasExited) {
            Stop-Process -Id $process.Id -Force
        }
    }
}

if (-not (Test-Path $PythonExe)) {
    throw "Missing Orchestrator Python executable at $PythonExe"
}

New-Item -ItemType Directory -Force -Path $ProfilesDir | Out-Null

$envMap = Load-DotEnv -Path $EnvPath

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputPath = Join-Path $ProfilesDir ("domain_runtime_profile_{0}.json" -f $timestamp)
}

$control = Run-IsolatedDomainProfile `
    -ModelName $ControlModel `
    -Port $ControlPort `
    -EnvMap $envMap `
    -HostName $ListenHost `
    -TimeoutSeconds $ProviderTimeoutSeconds `
    -EvalCasesPath $CasesPath

$candidate = Run-IsolatedDomainProfile `
    -ModelName $CandidateModel `
    -Port $CandidatePort `
    -EnvMap $envMap `
    -HostName $ListenHost `
    -TimeoutSeconds $ProviderTimeoutSeconds `
    -EvalCasesPath $CasesPath

$summary = [ordered]@{
    status = if ($control.eval_status -eq "passed" -and $candidate.eval_status -eq "passed") { "passed" } else { "failed" }
    control = $control
    candidate = $candidate
    comparison = [ordered]@{
        warmup_ms_delta_candidate_minus_control = [math]::Round(($candidate.warmup_ms - $control.warmup_ms), 2)
        eval_duration_ms_delta_candidate_minus_control = [math]::Round(($candidate.eval_duration_ms - $control.eval_duration_ms), 2)
        total_profile_ms_delta_candidate_minus_control = [math]::Round(($candidate.total_profile_ms - $control.total_profile_ms), 2)
        candidate_faster_on_warmup = ($candidate.warmup_ms -lt $control.warmup_ms)
        candidate_faster_on_eval = ($candidate.eval_duration_ms -lt $control.eval_duration_ms)
        candidate_faster_overall = ($candidate.total_profile_ms -lt $control.total_profile_ms)
    }
}

$summary | ConvertTo-Json -Depth 12 | Set-Content $OutputPath

Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 12)

if ($summary.status -ne "passed") {
    throw "Domain task candidate runtime profile surface failed."
}

Write-Host ""
Write-Host "Domain task candidate runtime profile surface passed." -ForegroundColor Green
