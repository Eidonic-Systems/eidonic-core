param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [Parameter(Mandatory = $true)]
    [string[]]$Notes,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SessionLogPath = Join-Path $RepoRoot "docs\SESSION_LOG.md"

if (-not (Test-Path $SessionLogPath)) {
    throw "Missing session log at $SessionLogPath"
}

$dateStamp = Get-Date -Format "yyyy-MM-dd"
$entryLines = [System.Collections.ArrayList]::new()

[void]$entryLines.Add("")
[void]$entryLines.Add("## $dateStamp")
[void]$entryLines.Add(('- Created branch `' + $BranchName + '`'))

foreach ($note in $Notes) {
    if ([string]::IsNullOrWhiteSpace($note)) {
        continue
    }

    if ($note.StartsWith("- ")) {
        [void]$entryLines.Add($note)
    }
    else {
        [void]$entryLines.Add("- $note")
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run for session log append:" -ForegroundColor Yellow
    $entryLines | ForEach-Object { Write-Host $_ }
    return
}

$entryLines | Add-Content $SessionLogPath

Write-Host ""
Write-Host "Session log entry appended." -ForegroundColor Green
Get-Content $SessionLogPath -Tail 14
