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
$projectStatePath = Join-Path $resolvedRepoRoot "docs\PROJECT_STATE_AT_A_GLANCE.md"
$manifestPath = Join-Path $resolvedRepoRoot "config\recovery_surface_manifest.json"

if (-not (Test-Path $projectStatePath)) {
    throw "Missing project-state surface at $projectStatePath"
}

if (-not (Test-Path $manifestPath)) {
    throw "Missing recovery-surface manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$requiredTruthSurfaces = @($manifest.project_state_required_references)
$requiredSections = @($manifest.project_state_required_sections)

foreach ($relativePath in $requiredTruthSurfaces) {
    $absolutePath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        throw "Missing required truth surface on disk: $relativePath"
    }
}

$projectStateText = Get-Content $projectStatePath -Raw
$failures = [System.Collections.ArrayList]::new()

foreach ($relativePath in $requiredTruthSurfaces) {
    $forwardPattern = [regex]::Escape([string]$relativePath)
    $backslashPattern = [regex]::Escape(([string]$relativePath).Replace("/", "\"))

    if (($projectStateText -notmatch $forwardPattern) -and ($projectStateText -notmatch $backslashPattern)) {
        Add-Failure -Failures $failures -Message ("project-state surface missing truth reference '{0}'" -f $relativePath)
    }
}

foreach ($sectionHeading in $requiredSections) {
    $headingText = [string]$sectionHeading
    if ($projectStateText -notmatch [regex]::Escape($headingText)) {
        Add-Failure -Failures $failures -Message ("project-state surface missing required section heading '{0}'" -f $headingText)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    recovery_surface_manifest_path = $manifestPath
    project_state_path = $projectStatePath
    required_truth_surface_count = $requiredTruthSurfaces.Count
    required_section_count = $requiredSections.Count
    failures = @($failures)
}

Write-Host ""
Write-Host "Project-state surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Project-state surface validation failed."
}

Write-Host ""
Write-Host "Project-state surface validation passed." -ForegroundColor Green
