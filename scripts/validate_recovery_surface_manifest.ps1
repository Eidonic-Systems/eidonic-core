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
$manifestPath = Join-Path $resolvedRepoRoot "config\recovery_surface_manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing recovery-surface manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    Add-Failure -Failures $failures -Message "recovery-surface manifest missing manifest_version"
}

$codexSurfaceChecks = @($manifest.codex_surface_checks)
if ($codexSurfaceChecks.Count -eq 0) {
    Add-Failure -Failures $failures -Message "recovery-surface manifest has no codex_surface_checks"
}

$pathsSeen = [System.Collections.ArrayList]::new()
foreach ($surfaceCheck in $codexSurfaceChecks) {
    $relativePath = [string]$surfaceCheck.path
    $requiredPatterns = @($surfaceCheck.required_patterns)

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        Add-Failure -Failures $failures -Message "codex surface check missing path"
        continue
    }

    if ($relativePath -in $pathsSeen) {
        Add-Failure -Failures $failures -Message ("duplicate codex surface path '{0}'" -f $relativePath)
    }
    else {
        [void]$pathsSeen.Add($relativePath)
    }

    $absolutePath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        Add-Failure -Failures $failures -Message ("codex surface path missing on disk: '{0}'" -f $relativePath)
    }

    if ($null -eq $surfaceCheck.required_patterns) {
        Add-Failure -Failures $failures -Message ("codex surface check '{0}' missing required_patterns" -f $relativePath)
    }
}

$projectStateRequiredReferences = @($manifest.project_state_required_references)
if ($projectStateRequiredReferences.Count -eq 0) {
    Add-Failure -Failures $failures -Message "recovery-surface manifest has no project_state_required_references"
}

$projectReferenceSeen = [System.Collections.ArrayList]::new()
foreach ($relativePath in $projectStateRequiredReferences) {
    $pathText = [string]$relativePath

    if ([string]::IsNullOrWhiteSpace($pathText)) {
        Add-Failure -Failures $failures -Message "project_state_required_references contains an empty entry"
        continue
    }

    if ($pathText -in $projectReferenceSeen) {
        Add-Failure -Failures $failures -Message ("duplicate project_state_required_reference '{0}'" -f $pathText)
    }
    else {
        [void]$projectReferenceSeen.Add($pathText)
    }

    $absolutePath = Join-Path $resolvedRepoRoot $pathText
    if (-not (Test-Path $absolutePath)) {
        Add-Failure -Failures $failures -Message ("project-state required reference missing on disk: '{0}'" -f $pathText)
    }
}

$projectStateRequiredSections = @($manifest.project_state_required_sections)
if ($projectStateRequiredSections.Count -eq 0) {
    Add-Failure -Failures $failures -Message "recovery-surface manifest has no project_state_required_sections"
}

$sectionSeen = [System.Collections.ArrayList]::new()
foreach ($sectionHeading in $projectStateRequiredSections) {
    $headingText = [string]$sectionHeading

    if ([string]::IsNullOrWhiteSpace($headingText)) {
        Add-Failure -Failures $failures -Message "project_state_required_sections contains an empty entry"
        continue
    }

    if ($headingText -in $sectionSeen) {
        Add-Failure -Failures $failures -Message ("duplicate project_state_required_section '{0}'" -f $headingText)
    }
    else {
        [void]$sectionSeen.Add($headingText)
    }

    if ($headingText -notmatch '^## ') {
        Add-Failure -Failures $failures -Message ("project_state_required_section must be a level-2 heading: '{0}'" -f $headingText)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    codex_surface_check_count = $codexSurfaceChecks.Count
    project_state_required_reference_count = $projectStateRequiredReferences.Count
    project_state_required_section_count = $projectStateRequiredSections.Count
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
