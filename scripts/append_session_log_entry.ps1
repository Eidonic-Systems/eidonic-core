param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [Parameter(Mandatory = $true)]
    [string]$NotesText,
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

$notes = @($NotesText -split "(`r`n|`n|`r)" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

foreach ($note in $notes) {
    $trimmed = $note.Trim()

    if ($trimmed.StartsWith("- ")) {
        [void]$entryLines.Add($trimmed)
    }
    else {
        [void]$entryLines.Add("- $trimmed")
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
