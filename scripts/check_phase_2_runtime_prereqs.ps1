$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $RepoRoot ".env"
$OrchestratorPython = Join-Path $RepoRoot "services\eidon-orchestrator\.venv\Scripts\python.exe"

function Load-DotEnv {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Missing .env file at $Path"
    }

    $map = @{}

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

function Assert-EnvKey {
    param(
        [hashtable]$EnvMap,
        [string]$Key
    )

    if (-not $EnvMap.ContainsKey($Key)) {
        throw "Missing required .env key: $Key"
    }

    if ([string]::IsNullOrWhiteSpace($EnvMap[$Key])) {
        throw "Required .env key is empty: $Key"
    }
}

function Write-Step {
    param(
        [string]$Message
    )

    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Running Phase 2 runtime preflight..." -ForegroundColor Cyan

$envMap = Load-DotEnv -Path $EnvPath

Write-Step "Checking required .env keys..."

Assert-EnvKey -EnvMap $envMap -Key "ORCHESTRATOR_POSTGRES_DSN"
Assert-EnvKey -EnvMap $envMap -Key "EIDON_PROVIDER_BACKEND"
Assert-EnvKey -EnvMap $envMap -Key "EIDON_PROVIDER_MODEL"

$providerBackend = $envMap["EIDON_PROVIDER_BACKEND"].Trim().ToLowerInvariant()
$providerModel = $envMap["EIDON_PROVIDER_MODEL"].Trim()

if ($providerBackend -eq "ollama") {
    Assert-EnvKey -EnvMap $envMap -Key "OLLAMA_BASE_URL"
}

Write-Host "Required .env keys are present." -ForegroundColor Green

Write-Step "Checking Orchestrator Python environment..."

if (-not (Test-Path $OrchestratorPython)) {
    throw "Missing Orchestrator Python executable at $OrchestratorPython"
}

Write-Host "Orchestrator Python executable is present." -ForegroundColor Green

Write-Step "Checking PostgreSQL reachability..."

$env:PHASE2_PREFLIGHT_DSN = $envMap["ORCHESTRATOR_POSTGRES_DSN"]

try {
    & $OrchestratorPython -c "import os, psycopg; conn = psycopg.connect(os.environ['PHASE2_PREFLIGHT_DSN']); cur = conn.cursor(); cur.execute('select 1;'); print('postgres ok'); conn.close()"
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL reachability check failed."
    }
}
finally {
    Remove-Item Env:PHASE2_PREFLIGHT_DSN -ErrorAction SilentlyContinue
}

Write-Host "PostgreSQL is reachable." -ForegroundColor Green

if ($providerBackend -eq "ollama") {
    Write-Step "Checking Ollama reachability and model presence..."

    $ollamaBaseUrl = $envMap["OLLAMA_BASE_URL"].Trim().TrimEnd("/")

    $tags = Invoke-RestMethod -Uri "$ollamaBaseUrl/tags" -Method Get

    if ($null -eq $tags.models) {
        throw "Ollama tags response did not include a models list."
    }

    $modelNames = @()
    foreach ($model in $tags.models) {
        if ($null -ne $model.name -and -not [string]::IsNullOrWhiteSpace($model.name)) {
            $modelNames += [string]$model.name
        }
        elseif ($null -ne $model.model -and -not [string]::IsNullOrWhiteSpace($model.model)) {
            $modelNames += [string]$model.model
        }
    }

    if ($modelNames -notcontains $providerModel) {
        throw "Configured Ollama model is not available locally: $providerModel"
    }

    Write-Host "Ollama is reachable." -ForegroundColor Green
    Write-Host "Configured Ollama model is available locally: $providerModel" -ForegroundColor Green
}
elseif ($providerBackend -eq "stub") {
    Write-Step "Checking stub provider configuration..."
    Write-Host "Stub provider selected. Remote runtime checks are not required." -ForegroundColor Green
}
else {
    throw "Unsupported provider backend in .env: $providerBackend"
}

Write-Host ""
Write-Host "Phase 2 runtime preflight passed." -ForegroundColor Green
