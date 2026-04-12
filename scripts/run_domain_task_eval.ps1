param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$CasesPath = ".\evals\domain_task_eval_cases.json",
    [string]$OutputPath = ".\evals\domain_task_eval_results.json"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Runner = Join-Path $RepoRoot "scripts\run_local_provider_eval.ps1"

& powershell -ExecutionPolicy Bypass -File $Runner `
    -EidonBaseUrl $EidonBaseUrl `
    -CasesPath $CasesPath `
    -OutputPath $OutputPath

if ($LASTEXITCODE -ne 0) {
    throw "Domain task eval surface failed."
}

$results = Get-Content $OutputPath -Raw | ConvertFrom-Json

Write-Host ""
Write-Host ("Domain task eval cases: {0}" -f $results.total_cases) -ForegroundColor Cyan
Write-Host ("Domain task eval passed: {0}" -f $results.passed_cases) -ForegroundColor Green
Write-Host ("Domain task eval failed: {0}" -f $results.failed_cases) -ForegroundColor Yellow
Write-Host ""
Write-Host "Domain task eval surface passed." -ForegroundColor Green
