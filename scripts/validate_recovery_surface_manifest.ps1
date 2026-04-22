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

function Test-UniquePathArray {
    param(
        [object[]]$Values,
        [string]$Label,
        [string]$RepoRootPath,
        [System.Collections.ArrayList]$Failures
    )

    if (@($Values).Count -eq 0) {
        Add-Failure -Failures $Failures -Message ("recovery-surface manifest has no {0}" -f $Label)
        return
    }

    $seen = [System.Collections.ArrayList]::new()

    foreach ($value in @($Values)) {
        $text = [string]$value

        if ([string]::IsNullOrWhiteSpace($text)) {
            Add-Failure -Failures $Failures -Message ("{0} contains an empty entry" -f $Label)
            continue
        }

        if ($text -in $seen) {
            Add-Failure -Failures $Failures -Message ("duplicate {0} '{1}'" -f $Label.TrimEnd('s'), $text)
        }
        else {
            [void]$seen.Add($text)
        }

        $absolutePath = Join-Path $RepoRootPath $text
        if (-not (Test-Path $absolutePath)) {
            Add-Failure -Failures $Failures -Message ("{0} missing on disk: '{1}'" -f $Label.TrimEnd('s'), $text)
        }
    }
}

function Test-UniqueHeadingArray {
    param(
        [object[]]$Values,
        [string]$Label,
        [System.Collections.ArrayList]$Failures
    )

    if (@($Values).Count -eq 0) {
        Add-Failure -Failures $Failures -Message ("recovery-surface manifest has no {0}" -f $Label)
        return
    }

    $seen = [System.Collections.ArrayList]::new()

    foreach ($value in @($Values)) {
        $text = [string]$value

        if ([string]::IsNullOrWhiteSpace($text)) {
            Add-Failure -Failures $Failures -Message ("{0} contains an empty entry" -f $Label)
            continue
        }

        if ($text -in $seen) {
            Add-Failure -Failures $Failures -Message ("duplicate {0} '{1}'" -f $Label.TrimEnd('s'), $text)
        }
        else {
            [void]$seen.Add($text)
        }

        if ($text -notmatch '^## ') {
            Add-Failure -Failures $Failures -Message ("{0} must be a level-2 heading: '{1}'" -f $Label.TrimEnd('s'), $text)
        }
    }
}

function Test-SurfaceChecks {
    param(
        [object[]]$Checks,
        [string]$Label,
        [string]$RepoRootPath,
        [System.Collections.ArrayList]$Failures
    )

    if (@($Checks).Count -eq 0) {
        Add-Failure -Failures $Failures -Message ("recovery-surface manifest has no {0}" -f $Label)
        return
    }

    $pathsSeen = [System.Collections.ArrayList]::new()

    foreach ($surfaceCheck in @($Checks)) {
        $relativePath = [string]$surfaceCheck.path

        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            Add-Failure -Failures $Failures -Message ("{0} contains a check with no path" -f $Label)
            continue
        }

        if ($relativePath -in $pathsSeen) {
            Add-Failure -Failures $Failures -Message ("duplicate {0} path '{1}'" -f $Label.TrimEnd('s'), $relativePath)
        }
        else {
            [void]$pathsSeen.Add($relativePath)
        }

        $absolutePath = Join-Path $RepoRootPath $relativePath
        if (-not (Test-Path $absolutePath)) {
            Add-Failure -Failures $Failures -Message ("{0} path missing on disk: '{1}'" -f $Label.TrimEnd('s'), $relativePath)
        }

        if ($null -eq $surfaceCheck.required_patterns) {
            Add-Failure -Failures $Failures -Message ("{0} '{1}' missing required_patterns" -f $Label.TrimEnd('s'), $relativePath)
        }
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\recovery_surface_manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing recovery-surface manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    Add-Failure -Failures $failures -Message "recovery-surface manifest missing manifest_version"
}

Test-SurfaceChecks -Checks @($manifest.codex_surface_checks) -Label 'codex_surface_checks' -RepoRootPath $resolvedRepoRoot -Failures $failures
Test-SurfaceChecks -Checks @($manifest.root_doc_surface_checks) -Label 'root_doc_surface_checks' -RepoRootPath $resolvedRepoRoot -Failures $failures

Test-UniquePathArray -Values @($manifest.project_state_required_references) -Label 'project_state_required_references' -RepoRootPath $resolvedRepoRoot -Failures $failures
Test-UniqueHeadingArray -Values @($manifest.project_state_required_sections) -Label 'project_state_required_sections' -Failures $failures
Test-UniquePathArray -Values @($manifest.scripts_readme_required_references) -Label 'scripts_readme_required_references' -RepoRootPath $resolvedRepoRoot -Failures $failures
Test-UniqueHeadingArray -Values @($manifest.scripts_readme_required_sections) -Label 'scripts_readme_required_sections' -Failures $failures

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    codex_surface_check_count = @($manifest.codex_surface_checks).Count
    root_doc_surface_check_count = @($manifest.root_doc_surface_checks).Count
    project_state_required_reference_count = @($manifest.project_state_required_references).Count
    project_state_required_section_count = @($manifest.project_state_required_sections).Count
    scripts_readme_required_reference_count = @($manifest.scripts_readme_required_references).Count
    scripts_readme_required_section_count = @($manifest.scripts_readme_required_sections).Count
    failures = @($failures)
}

Write-Host ""
Write-Host "Recovery-surface manifest validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Recovery-surface manifest validation failed."
}

Write-Host ""
Write-Host "Recovery-surface manifest validation passed." -ForegroundColor Green
