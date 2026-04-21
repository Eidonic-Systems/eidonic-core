param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Add-Failure {
    param(
        [System.Collections.ArrayList]$Failures,
        [string]$Message
    )

    [void]$Failures.Add($Message)
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\phase2_gate_surface_manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing Phase 2 gate surface manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    Add-Failure -Failures $failures -Message "gate surface manifest missing manifest_version"
}

$validationSteps = @($manifest.validation_steps)
if ($validationSteps.Count -eq 0) {
    Add-Failure -Failures $failures -Message "gate surface manifest has no validation_steps"
}

$labelsSeen = [System.Collections.ArrayList]::new()
$pathsSeen = [System.Collections.ArrayList]::new()

foreach ($step in $validationSteps) {
    $label = [string]$step.label
    $relativePath = [string]$step.script_path

    if ([string]::IsNullOrWhiteSpace($label)) {
        Add-Failure -Failures $failures -Message "gate surface validation step missing label"
    }
    elseif ($label -in $labelsSeen) {
        Add-Failure -Failures $failures -Message ("duplicate gate surface validation label '{0}'" -f $label)
    }
    else {
        [void]$labelsSeen.Add($label)
    }

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        Add-Failure -Failures $failures -Message ("gate surface validation step '{0}' missing script_path" -f $label)
        continue
    }

    if ($relativePath -in $pathsSeen) {
        Add-Failure -Failures $failures -Message ("duplicate gate surface validation script_path '{0}'" -f $relativePath)
    }
    else {
        [void]$pathsSeen.Add($relativePath)
    }

    if ($relativePath -notmatch '^scripts[\\/].+\.ps1$') {
        Add-Failure -Failures $failures -Message ("gate surface validation script_path must point to a PowerShell script under scripts/: '{0}'" -f $relativePath)
    }

    $resolvedStepPath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $resolvedStepPath)) {
        Add-Failure -Failures $failures -Message ("gate surface validation script missing on disk: '{0}'" -f $relativePath)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    validation_step_count = $validationSteps.Count
    failures = @($failures)
}

Write-Host ""
Write-Host "Phase 2 gate surface manifest validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Phase 2 gate surface manifest validation failed."
}

Write-Host ""
Write-Host "Phase 2 gate surface manifest validation passed." -ForegroundColor Green
