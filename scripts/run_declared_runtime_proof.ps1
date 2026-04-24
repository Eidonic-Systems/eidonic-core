param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [string]$RepoRoot = ".",
    [switch]$SkipStackStart
)

$ErrorActionPreference = "Stop"

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot 'config\phase2_gate_surface_manifest.json'
$resolvedScriptPath = [System.IO.Path]::GetFullPath((Join-Path $resolvedRepoRoot $ScriptPath))

if (-not (Test-Path $manifestPath)) {
    throw "Missing gate surface manifest at $manifestPath"
}

if (-not (Test-Path $resolvedScriptPath)) {
    throw "Requested runtime proof script does not exist: $resolvedScriptPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$declaredRuntimeSteps = @($manifest.post_start_runtime_steps | ForEach-Object { [System.IO.Path]::GetFullPath((Join-Path $resolvedRepoRoot ([string]$_.script_path))) })

if ($resolvedScriptPath -notin $declaredRuntimeSteps) {
    throw "Requested script is not declared under post_start_runtime_steps: $ScriptPath"
}

if (-not $SkipStackStart) {
    Write-Host ""
    Write-Host "Starting Phase 2 stack once for runtime proof..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File (Join-Path $resolvedRepoRoot 'scripts\start_phase_2_stack.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw "Phase 2 stack startup failed before runtime proof."
    }
}

Write-Host ""
Write-Host ("Running declared runtime proof: {0}" -f $ScriptPath) -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $resolvedScriptPath -RepoRoot $resolvedRepoRoot
if ($LASTEXITCODE -ne 0) {
    throw ("Declared runtime proof failed: {0}" -f $ScriptPath)
}

Write-Host ""
Write-Host "Declared runtime proof completed." -ForegroundColor Green
