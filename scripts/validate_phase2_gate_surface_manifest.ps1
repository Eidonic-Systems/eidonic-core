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

function Test-StepArray {
    param(
        [object[]]$Steps,
        [string]$Label,
        [string]$RepoRootPath,
        [System.Collections.ArrayList]$Failures,
        [System.Collections.ArrayList]$LabelsSeen,
        [System.Collections.ArrayList]$PathsSeen
    )

    if (@($Steps).Count -eq 0) {
        Add-Failure -Failures $Failures -Message ("gate surface manifest has no {0}" -f $Label)
        return
    }

    foreach ($step in @($Steps)) {
        $stepLabel = [string]$step.label
        $relativePath = [string]$step.script_path

        if ([string]::IsNullOrWhiteSpace($stepLabel)) {
            Add-Failure -Failures $Failures -Message ("{0} contains a step with no label" -f $Label)
        }
        elseif ($stepLabel -in $LabelsSeen) {
            Add-Failure -Failures $Failures -Message ("duplicate gate surface step label '{0}'" -f $stepLabel)
        }
        else {
            [void]$LabelsSeen.Add($stepLabel)
        }

        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            Add-Failure -Failures $Failures -Message ("{0} step '{1}' missing script_path" -f $Label, $stepLabel)
            continue
        }

        if ($relativePath -in $PathsSeen) {
            Add-Failure -Failures $Failures -Message ("duplicate gate surface script_path '{0}'" -f $relativePath)
        }
        else {
            [void]$PathsSeen.Add($relativePath)
        }

        if ($relativePath -notmatch '^scripts[\\/].+\.ps1$') {
            Add-Failure -Failures $Failures -Message ("gate surface script_path must point to a PowerShell script under scripts/: '{0}'" -f $relativePath)
        }

        $resolvedStepPath = Join-Path $RepoRootPath $relativePath
        if (-not (Test-Path $resolvedStepPath)) {
            Add-Failure -Failures $Failures -Message ("gate surface script missing on disk: '{0}'" -f $relativePath)
        }
    }
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

foreach ($requiredPhase in @('validation_steps', 'startup_authority_steps', 'post_start_runtime_steps')) {
    if (-not ($manifest.PSObject.Properties.Name -contains $requiredPhase)) {
        Add-Failure -Failures $failures -Message ("gate surface manifest missing {0}" -f $requiredPhase)
    }
}

$labelsSeen = [System.Collections.ArrayList]::new()
$pathsSeen = [System.Collections.ArrayList]::new()

Test-StepArray -Steps @($manifest.validation_steps) -Label 'validation_steps' -RepoRootPath $resolvedRepoRoot -Failures $failures -LabelsSeen $labelsSeen -PathsSeen $pathsSeen
Test-StepArray -Steps @($manifest.startup_authority_steps) -Label 'startup_authority_steps' -RepoRootPath $resolvedRepoRoot -Failures $failures -LabelsSeen $labelsSeen -PathsSeen $pathsSeen
Test-StepArray -Steps @($manifest.post_start_runtime_steps) -Label 'post_start_runtime_steps' -RepoRootPath $resolvedRepoRoot -Failures $failures -LabelsSeen $labelsSeen -PathsSeen $pathsSeen

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    validation_step_count = @($manifest.validation_steps).Count
    startup_authority_step_count = @($manifest.startup_authority_steps).Count
    post_start_runtime_step_count = @($manifest.post_start_runtime_steps).Count
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
