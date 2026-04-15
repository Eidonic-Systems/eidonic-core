param(
    [string]$RepoRoot = ".",
    [string[]]$RequiredModels = @("gemma3n:e4b", "gemma3n:e2b"),
    [switch]$CheckRunnerFolder
)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Add-CheckResult {
    param(
        [System.Collections.ArrayList]$Results,
        [string]$Name,
        [bool]$Passed,
        [string]$Detail
    )

    [void]$Results.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        detail = $Detail
    })
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$results = [System.Collections.ArrayList]::new()

# Basic host tools
$gitOk = Test-CommandExists git
Add-CheckResult -Results $results -Name "git_available" -Passed $gitOk -Detail ($(if ($gitOk) { (git --version) } else { "git not found on PATH" }))

$pythonOk = Test-CommandExists python
Add-CheckResult -Results $results -Name "python_available" -Passed $pythonOk -Detail ($(if ($pythonOk) { (python --version) } else { "python not found on PATH" }))

$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
$ollamaOk = $null -ne $ollamaCmd
Add-CheckResult -Results $results -Name "ollama_available" -Passed $ollamaOk -Detail ($(if ($ollamaOk) { $ollamaCmd.Source } else { "ollama not found on PATH" }))

# PostgreSQL client
$psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
$psqlPath = $null
if ($null -ne $psqlCmd) {
    $psqlPath = $psqlCmd.Source
}
else {
    $candidate = Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter psql.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\bin\\psql\.exe$' } |
        Select-Object -First 1

    if ($null -ne $candidate) {
        $psqlPath = $candidate.FullName
    }
}

$psqlOk = -not [string]::IsNullOrWhiteSpace($psqlPath)
Add-CheckResult -Results $results -Name "postgresql_client_available" -Passed $psqlOk -Detail ($(if ($psqlOk) { $psqlPath } else { "psql.exe not found" }))

# Repo root files
$envPath = Join-Path $resolvedRepoRoot ".env"
$envOk = Test-Path $envPath
Add-CheckResult -Results $results -Name "repo_env_present" -Passed $envOk -Detail ($(if ($envOk) { $envPath } else { "missing .env at repo root" }))

$exampleEnvPath = Join-Path $resolvedRepoRoot ".env.example"
$exampleEnvOk = Test-Path $exampleEnvPath
Add-CheckResult -Results $results -Name "repo_env_example_present" -Passed $exampleEnvOk -Detail ($(if ($exampleEnvOk) { $exampleEnvPath } else { "missing .env.example at repo root" }))

# Service venvs
$serviceNames = @(
    "eidon-orchestrator",
    "signal-gateway",
    "session-engine",
    "herald-service"
)

foreach ($serviceName in $serviceNames) {
    $venvPython = Join-Path $resolvedRepoRoot ("services\{0}\.venv\Scripts\python.exe" -f $serviceName)
    $venvOk = Test-Path $venvPython
    Add-CheckResult -Results $results -Name ("service_venv_{0}" -f $serviceName) -Passed $venvOk -Detail ($(if ($venvOk) { $venvPython } else { "missing venv python for $serviceName" }))
}

# Ollama models
if ($ollamaOk) {
    $ollamaListRaw = & ollama list 2>$null
    foreach ($model in $RequiredModels) {
        $modelOk = $false
        if ($null -ne $ollamaListRaw) {
            $modelOk = ($ollamaListRaw | Select-String -Pattern ([regex]::Escape($model)) -Quiet)
        }

        Add-CheckResult -Results $results -Name ("ollama_model_{0}" -f ($model -replace '[:\.]', '_')) -Passed $modelOk -Detail ($(if ($modelOk) { "$model present" } else { "$model missing" }))
    }
}
else {
    foreach ($model in $RequiredModels) {
        Add-CheckResult -Results $results -Name ("ollama_model_{0}" -f ($model -replace '[:\.]', '_')) -Passed $false -Detail ("cannot check $model because ollama is unavailable")
    }
}

# Optional runner folder check
if ($CheckRunnerFolder) {
    $runnerPath = "C:\actions-runner\run.cmd"
    $runnerOk = Test-Path $runnerPath
    Add-CheckResult -Results $results -Name "self_hosted_runner_folder" -Passed $runnerOk -Detail ($(if ($runnerOk) { $runnerPath } else { "missing C:\actions-runner\run.cmd" }))
}

$failed = @($results | Where-Object { -not $_.passed })

$summary = [ordered]@{
    status = $(if ($failed.Count -eq 0) { "passed" } else { "failed" })
    repo_root = $resolvedRepoRoot
    total_checks = $results.Count
    failed_checks = $failed.Count
    results = $results
}

Write-Host ""
Write-Host "Phase 2 host bootstrap check summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Phase 2 host bootstrap check failed."
}

Write-Host ""
Write-Host "Phase 2 host bootstrap check passed." -ForegroundColor Green
