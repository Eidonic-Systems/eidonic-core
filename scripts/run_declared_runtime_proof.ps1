param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [string]$RepoRoot = ".",
    [ValidateSet('startup_authority_steps', 'post_start_runtime_steps')]
    [string]$PhaseName,
    [switch]$SkipStackStart,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Get-DeclaredProofPhase {
    param(
        [object]$Manifest,
        [string]$ResolvedRepoRoot,
        [string]$ResolvedScriptPath,
        [string]$RequestedPhaseName
    )

    $allowedPhases = @('startup_authority_steps', 'post_start_runtime_steps')

    if (-not [string]::IsNullOrWhiteSpace($RequestedPhaseName)) {
        $phaseSteps = @($Manifest.$RequestedPhaseName)
        $declaredPaths = @($phaseSteps | ForEach-Object {
            [System.IO.Path]::GetFullPath((Join-Path $ResolvedRepoRoot ([string]$_.script_path)))
        })

        if ($ResolvedScriptPath -notin $declaredPaths) {
            throw ("Requested script is not declared under {0}: {1}" -f $RequestedPhaseName, $ScriptPath)
        }

        return $RequestedPhaseName
    }

    $matchedPhases = New-Object System.Collections.ArrayList

    foreach ($phase in $allowedPhases) {
        $phaseSteps = @($Manifest.$phase)
        $declaredPaths = @($phaseSteps | ForEach-Object {
            [System.IO.Path]::GetFullPath((Join-Path $ResolvedRepoRoot ([string]$_.script_path)))
        })

        if ($ResolvedScriptPath -in $declaredPaths) {
            [void]$matchedPhases.Add($phase)
        }
    }

    if ($matchedPhases.Count -eq 0) {
        throw "Requested script is not declared under allowed proof phases: startup_authority_steps, post_start_runtime_steps: $ScriptPath"
    }

    if ($matchedPhases.Count -gt 1) {
        throw "Requested script was declared in multiple allowed proof phases, which is invalid: $ScriptPath"
    }

    return [string]$matchedPhases[0]
}

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
$resolvedPhaseName = Get-DeclaredProofPhase -Manifest $manifest -ResolvedRepoRoot $resolvedRepoRoot -ResolvedScriptPath $resolvedScriptPath -RequestedPhaseName $PhaseName

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run for declared gate-phase proof helper:" -ForegroundColor Yellow
    Write-Host ("  script path: {0}" -f $ScriptPath)
    Write-Host ("  resolved declared phase: {0}" -f $resolvedPhaseName)

    if ($resolvedPhaseName -eq 'startup_authority_steps') {
        Write-Host "  no pre-start stack call is allowed for startup_authority_steps" -ForegroundColor Cyan
    }
    elseif ($SkipStackStart) {
        Write-Host "  Skipping pre-start stack call because -SkipStackStart was used." -ForegroundColor Cyan
    }
    else {
        Write-Host "  Would start Phase 2 stack once before runtime proof." -ForegroundColor Cyan
    }

    Write-Host ("  Would run declared proof: {0}" -f $ScriptPath) -ForegroundColor Cyan
    return
}

if ($resolvedPhaseName -eq 'post_start_runtime_steps' -and -not $SkipStackStart) {
    Write-Host ""
    Write-Host "Starting Phase 2 stack once for post-start runtime proof..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File (Join-Path $resolvedRepoRoot 'scripts\start_phase_2_stack.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw "Phase 2 stack startup failed before post-start runtime proof."
    }
}

Write-Host ""
Write-Host ("Running declared proof from {0}: {1}" -f $resolvedPhaseName, $ScriptPath) -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $resolvedScriptPath -RepoRoot $resolvedRepoRoot
if ($LASTEXITCODE -ne 0) {
    throw ("Declared proof failed from {0}: {1}" -f $resolvedPhaseName, $ScriptPath)
}

Write-Host ""
Write-Host "Declared gate-phase proof completed." -ForegroundColor Green

