param(
    [Parameter(Mandatory = $true)]
    [string]$CandidateModel,

    [string]$CandidateLabel = "",

    [string]$ListenHost = "127.0.0.1",

    [int]$Port = 8013,

    [string]$CasesPath = ".\evals\local_provider_eval_cases.json",

    [string]$BaselinePath = ".\evals\baselines\local_provider_eval_baseline.json",

    [int]$CandidateProviderTimeoutSeconds = 90
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $RepoRoot ".env"
$OrchestratorDir = Join-Path $RepoRoot "services\eidon-orchestrator"
$PythonExe = Join-Path $OrchestratorDir ".venv\Scripts\python.exe"
$EvalScript = Join-Path $RepoRoot "scripts\run_local_provider_eval.ps1"
$CompareScript = Join-Path $RepoRoot "scripts\compare_local_provider_eval_to_baseline.ps1"
$CandidateDir = Join-Path $RepoRoot "evals\candidates"

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

    throw "Candidate Orchestrator health did not become ready at $Url."
}

function Sanitize-Label {
    param(
        [string]$Value
    )

    $sanitized = $Value.ToLowerInvariant() -replace '[^a-z0-9\-_.]+', '-'
    $sanitized = $sanitized.Trim('-')

    if ([string]::IsNullOrWhiteSpace($sanitized)) {
        return "candidate"
    }

    return $sanitized
}

$envMap = Load-DotEnv -Path $EnvPath

if (-not (Test-Path $PythonExe)) {
    throw "Missing Orchestrator Python executable at $PythonExe"
}

New-Item -ItemType Directory -Force -Path $CandidateDir | Out-Null

$labelSource = if ([string]::IsNullOrWhiteSpace($CandidateLabel)) { $CandidateModel } else { $CandidateLabel }
$sanitizedLabel = Sanitize-Label -Value $labelSource
$currentResultsPath = Join-Path $CandidateDir ("local_provider_eval_candidate_{0}.json" -f $sanitizedLabel)

$ollamaBaseUrl = if ($envMap.ContainsKey("OLLAMA_BASE_URL") -and -not [string]::IsNullOrWhiteSpace($envMap["OLLAMA_BASE_URL"])) {
    $envMap["OLLAMA_BASE_URL"]
} else {
    "http://127.0.0.1:11434/api"
}

$providerKeepalive = if ($envMap.ContainsKey("EIDON_PROVIDER_WARM_KEEPALIVE") -and -not [string]::IsNullOrWhiteSpace($envMap["EIDON_PROVIDER_WARM_KEEPALIVE"])) {
    $envMap["EIDON_PROVIDER_WARM_KEEPALIVE"]
} else {
    "15m"
}

$candidateModelEscaped = $CandidateModel.Replace("'", "''")
$ollamaBaseUrlEscaped = $ollamaBaseUrl.Replace("'", "''")
$providerKeepaliveEscaped = $providerKeepalive.Replace("'", "''")
$orchestratorDirEscaped = $OrchestratorDir.Replace("'", "''")
$pythonExeEscaped = $PythonExe.Replace("'", "''")

$command = @"
`$env:EIDON_PROVIDER_BACKEND = 'ollama'
`$env:EIDON_PROVIDER_MODEL = '$candidateModelEscaped'
`$env:OLLAMA_BASE_URL = '$ollamaBaseUrlEscaped'
`$env:EIDON_PROVIDER_TIMEOUT_SECONDS = '$CandidateProviderTimeoutSeconds'
`$env:EIDON_PROVIDER_WARM_KEEPALIVE = '$providerKeepaliveEscaped'
Set-Location '$orchestratorDirEscaped'
& '$pythonExeEscaped' -m uvicorn app.main:app --host $ListenHost --port $Port
"@

$candidateProcess = $null

try {
    Write-Host ""
    Write-Host "Starting isolated candidate Orchestrator for model: $CandidateModel" -ForegroundColor Yellow
    Write-Host "Candidate provider timeout seconds: $CandidateProviderTimeoutSeconds" -ForegroundColor Yellow

    $candidateProcess = Start-Process powershell -ArgumentList @(
        '-ExecutionPolicy', 'Bypass',
        '-Command', $command
    ) -PassThru -WindowStyle Hidden

    Wait-For-Health -Url ("http://{0}:{1}/health" -f $ListenHost, $Port)

    Write-Host "Candidate Orchestrator health is ready." -ForegroundColor Green

    $warmResponse = Invoke-RestMethod -Uri ("http://{0}:{1}/provider/warm" -f $ListenHost, $Port) -Method Post
    Write-Host ""
    Write-Host ($warmResponse | ConvertTo-Json -Depth 12)

    if ($warmResponse.status -ne "warmed") {
        throw "Candidate provider warmup failed. Status was '$($warmResponse.status)'."
    }

    Write-Host "Candidate provider warmup completed." -ForegroundColor Green

    & powershell -ExecutionPolicy Bypass -File $EvalScript `
        -EidonBaseUrl ("http://{0}:{1}" -f $ListenHost, $Port) `
        -CasesPath $CasesPath `
        -OutputPath $currentResultsPath

    & powershell -ExecutionPolicy Bypass -File $CompareScript `
        -CurrentPath $currentResultsPath `
        -BaselinePath $BaselinePath

    Write-Host ""
    Write-Host ("Candidate comparison completed. Results file: {0}" -f $currentResultsPath) -ForegroundColor Green
}
finally {
    if ($null -ne $candidateProcess -and -not $candidateProcess.HasExited) {
        Stop-Process -Id $candidateProcess.Id -Force
    }
}
