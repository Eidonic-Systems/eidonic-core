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
Set-Location $resolvedRepoRoot

$repoShapePatterns = @(
    '^AGENTS\.md$',
    '^README\.md$',
    '^SECURITY\.md$',
    '^\.github/',
    '^\.agents/',
    '^\.codex/',
    '^config/',
    '^docs/',
    '^scripts/',
    '^services/',
    '^packages/',
    '^tests/'
)

$untrackedPaths = @(
    & git ls-files --others --exclude-standard |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { ($_ -replace '\\', '/').Trim() }
)

$repoShapeUntracked = [System.Collections.ArrayList]::new()
$otherUntracked = [System.Collections.ArrayList]::new()

foreach ($path in $untrackedPaths) {
    $isRepoShape = $false

    foreach ($pattern in $repoShapePatterns) {
        if ($path -match $pattern) {
            $isRepoShape = $true
            break
        }
    }

    if ($isRepoShape) {
        [void]$repoShapeUntracked.Add($path)
    }
    else {
        [void]$otherUntracked.Add($path)
    }
}

$failures = [System.Collections.ArrayList]::new()

if ($repoShapeUntracked.Count -gt 0) {
    Add-Failure -Failures $failures -Message "untracked repo-shape files detected; stage, remove, or ignore them before proof and commit"
}

if ($otherUntracked.Count -gt 0) {
    Add-Failure -Failures $failures -Message "untracked non-repo-shape files detected; remove or ignore them before cleanup and final proof"
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    repo_root = $resolvedRepoRoot
    ignored_files_excluded_via_git = $true
    repo_shape_untracked_count = $repoShapeUntracked.Count
    other_untracked_count = $otherUntracked.Count
    repo_shape_untracked = @($repoShapeUntracked)
    other_untracked = @($otherUntracked)
    failures = @($failures)
}

Write-Host ""
Write-Host "Untracked-file guard validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Untracked-file guard validation failed."
}

Write-Host ""
Write-Host "Untracked-file guard validation passed." -ForegroundColor Green
