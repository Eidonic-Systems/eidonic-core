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
$readmePath = Join-Path $resolvedRepoRoot "scripts\README.md"
$manifestPath = Join-Path $resolvedRepoRoot "config\recovery_surface_manifest.json"

if (-not (Test-Path $readmePath)) {
    throw "Missing scripts README surface at $readmePath"
}

if (-not (Test-Path $manifestPath)) {
    throw "Missing recovery-surface manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$requiredReferences = @($manifest.scripts_readme_required_references)
$requiredSections = @($manifest.scripts_readme_required_sections)
$readmeText = Get-Content $readmePath -Raw
$failures = [System.Collections.ArrayList]::new()

foreach ($relativePath in $requiredReferences) {
    $forwardPattern = [regex]::Escape([string]$relativePath)
    $backslashPattern = [regex]::Escape(([string]$relativePath).Replace("/", "\"))

    if (($readmeText -notmatch $forwardPattern) -and ($readmeText -notmatch $backslashPattern)) {
        Add-Failure -Failures $failures -Message ("scripts README missing required truth reference '{0}'" -f $relativePath)
    }
}

foreach ($sectionHeading in $requiredSections) {
    $headingText = [string]$sectionHeading
    if ($readmeText -notmatch [regex]::Escape($headingText)) {
        Add-Failure -Failures $failures -Message ("scripts README missing required section heading '{0}'" -f $headingText)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    recovery_surface_manifest_path = $manifestPath
    scripts_readme_path = $readmePath
    required_reference_count = $requiredReferences.Count
    required_section_count = $requiredSections.Count
    failures = @($failures)
}

Write-Host ""
Write-Host "Scripts README surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Scripts README surface validation failed."
}

Write-Host ""
Write-Host "Scripts README surface validation passed." -ForegroundColor Green
