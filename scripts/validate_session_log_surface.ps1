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
$sessionLogPath = Join-Path $resolvedRepoRoot "docs\SESSION_LOG.md"

if (-not (Test-Path $sessionLogPath)) {
    throw "Missing session-log surface at $sessionLogPath"
}

$lines = Get-Content $sessionLogPath
$failures = [System.Collections.ArrayList]::new()

$headingIndices = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## \d{4}-\d{2}-\d{2}$') {
        $headingIndices += $i
    }
}

if ($headingIndices.Count -eq 0) {
    Add-Failure -Failures $failures -Message "session log has no dated section headings"
}

$createdBranchCount = 0
$today = (Get-Date).Date

for ($sectionIndex = 0; $sectionIndex -lt $headingIndices.Count; $sectionIndex++) {
    $startIndex = $headingIndices[$sectionIndex]
    $endIndex = if ($sectionIndex -lt ($headingIndices.Count - 1)) { $headingIndices[$sectionIndex + 1] - 1 } else { $lines.Count - 1 }

    $headingLine = $lines[$startIndex]
    $dateText = $headingLine.Substring(3)

    try {
        $entryDate = [datetime]::ParseExact(
            $dateText,
            'yyyy-MM-dd',
            [System.Globalization.CultureInfo]::InvariantCulture
        )
    }
    catch {
        Add-Failure -Failures $failures -Message ("session log has invalid heading date '{0}'" -f $dateText)
        continue
    }

    if ($entryDate.Date -gt $today) {
        Add-Failure -Failures $failures -Message ("session log contains future-dated heading '{0}'" -f $dateText)
    }

    $sectionLines = @()
    if ($endIndex -gt $startIndex) {
        $sectionLines = @($lines[($startIndex + 1)..$endIndex])
    }

    $bulletLines = @($sectionLines | Where-Object { $_ -match '^- ' })
    if ($bulletLines.Count -eq 0) {
        Add-Failure -Failures $failures -Message ("session log section '{0}' has no bullet lines" -f $dateText)
    }

    foreach ($line in $sectionLines) {
        if ($line -match 'Created branch') {
            if ($line -match '^- Created branch `[^`]+`$') {
                $createdBranchCount++
            }
            else {
                Add-Failure -Failures $failures -Message ("session log has malformed created-branch line under '{0}': {1}" -f $dateText, $line)
            }
        }
    }
}

if ($createdBranchCount -eq 0) {
    Add-Failure -Failures $failures -Message "session log has no valid created-branch entries"
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    session_log_path = $sessionLogPath
    dated_section_count = $headingIndices.Count
    created_branch_count = $createdBranchCount
    failures = @($failures)
}

Write-Host ""
Write-Host "Session-log surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Session-log surface validation failed."
}

Write-Host ""
Write-Host "Session-log surface validation passed." -ForegroundColor Green
