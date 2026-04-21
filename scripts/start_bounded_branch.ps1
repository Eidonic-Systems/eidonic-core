param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

function Run-GitStep {
    param(
        [string]$Label,
        [string[]]$GitArgs
    )

    Write-Host ""
    Write-Host ("==> {0}" -f $Label) -ForegroundColor Yellow

    if ($DryRun) {
        Write-Host ("[DRY-RUN] git {0}" -f ($GitArgs -join " ")) -ForegroundColor Cyan
        return
    }

    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw ("git step failed: {0}" -f $Label)
    }
}

$existingBranch = (git branch --list $BranchName | Out-String).Trim()
if (-not [string]::IsNullOrWhiteSpace($existingBranch)) {
    throw "Local branch already exists: $BranchName"
}

if (-not $DryRun) {
    $workingTree = (git status --porcelain | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($workingTree)) {
        throw "Working tree is not clean. Clean it before creating a bounded branch."
    }
}

Run-GitStep -Label "Switching to main" -GitArgs @("switch", "main")
Run-GitStep -Label "Pulling latest main" -GitArgs @("pull", "--ff-only")
Run-GitStep -Label "Pruning remote refs" -GitArgs @("fetch", "--prune")
Run-GitStep -Label "Showing repo status" -GitArgs @("status")
Run-GitStep -Label ("Creating bounded branch {0}" -f $BranchName) -GitArgs @("switch", "-c", $BranchName)

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run completed for bounded branch start." -ForegroundColor Green
    return
}

Write-Host ""
Write-Host "Bounded branch created successfully." -ForegroundColor Green
& git branch --show-current
& git status
