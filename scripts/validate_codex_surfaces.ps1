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
$surfaceChecks = @($manifest.codex_surface_checks)

if ($surfaceChecks.Count -eq 0) {
    throw "Recovery-surface manifest has no codex_surface_checks."
}

$failures = [System.Collections.ArrayList]::new()
$checkedSurfaces = [System.Collections.ArrayList]::new()

foreach ($surfaceCheck in $surfaceChecks) {
    $relativePath = [string]$surfaceCheck.path
    $requiredPatterns = @($surfaceCheck.required_patterns)

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        Add-Failure -Failures $failures -Message "codex surface check missing path"
        continue
    }

    $absolutePath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        Add-Failure -Failures $failures -Message ("Missing required Codex surface at {0}" -f $absolutePath)
        continue
    }

    [void]$checkedSurfaces.Add($absolutePath)

    if ($requiredPatterns.Count -eq 0) {
        continue
    }

    $surfaceText = Get-Content $absolutePath -Raw
    foreach ($pattern in $requiredPatterns) {
        $patternText = [string]$pattern
        if ($surfaceText -notmatch $patternText) {
            Add-Failure -Failures $failures -Message ("{0} missing required pattern '{1}'" -f $relativePath, $patternText)
        }
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    recovery_surface_manifest_path = $manifestPath
    checked_surface_count = $checkedSurfaces.Count
    checked_surfaces = @($checkedSurfaces)
    failures = @($failures)
}

Write-Host ""
Write-Host "Codex surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Codex surface validation failed."
}

Write-Host ""
Write-Host "Codex surface validation passed." -ForegroundColor Green
