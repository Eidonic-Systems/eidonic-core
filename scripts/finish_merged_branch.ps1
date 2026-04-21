param(
    [Parameter(Mandatory = $true)]
    [string]$BranchName,
    [switch]$ForceDelete,
    [switch]$DryRun,
    [string[]]$TempFiles = @(
        "tmp_phase2_gate_output.txt",
        "tmp_test_full_chain_output.txt"
    )
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

function Get-DirtyWorkingTree {
    return @(
        (git status --short | Out-String).Trim().Split(
            [Environment]::NewLine,
            [System.StringSplitOptions]::RemoveEmptyEntries
        )
    )
}

function Test-LocalBranchExists {
    param(
        [string]$Name
    )

    $branchText = (git branch --list $Name | Out-String).Trim()
    return (-not [string]::IsNullOrWhiteSpace($branchText))
}

Write-Host ""
Write-Host "==> Pre-cleaning known temp output files" -ForegroundColor Yellow
foreach ($tempFile in $TempFiles) {
    $tempPath = Join-Path $RepoRoot $tempFile

    if ($DryRun) {
        Write-Host ("[DRY-RUN] remove-item {0}" -f $tempPath) -ForegroundColor Cyan
        continue
    }

    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
}

if (-not $DryRun) {
    $dirtyLines = Get-DirtyWorkingTree
    if ($dirtyLines.Count -gt 0) {
        Write-Host ""
        Write-Host "Working tree is dirty. Refusing merged-branch cleanup before pull." -ForegroundColor Red
        $dirtyLines | ForEach-Object { Write-Host $_ }
        throw "Working tree is not clean. Commit, restore, or stash changes before running finish_merged_branch.ps1."
    }
}

Run-GitStep -Label "Switching to main" -GitArgs @("switch", "main")
Run-GitStep -Label "Pulling latest main" -GitArgs @("pull", "--ff-only")
Run-GitStep -Label "Pruning remote refs" -GitArgs @("fetch", "--prune")
Run-GitStep -Label "Showing repo status" -GitArgs @("status")

Write-Host ""
Write-Host ("==> Cleaning local branch {0}" -f $BranchName) -ForegroundColor Yellow

if ($DryRun) {
    Write-Host ("[DRY-RUN] would check for local branch {0}" -f $BranchName) -ForegroundColor Cyan
    Write-Host ("[DRY-RUN] idempotent cleanup supports already-absent branch {0}" -f $BranchName) -ForegroundColor Cyan
}
else {
    if (Test-LocalBranchExists -Name $BranchName) {
        $deleteFlag = if ($ForceDelete) { "-D" } else { "-d" }
        & git branch $deleteFlag $BranchName
        if ($LASTEXITCODE -ne 0) {
            throw ("git step failed: Deleting local branch {0}" -f $BranchName)
        }

        Write-Host ("Deleted local branch {0}" -f $BranchName) -ForegroundColor Green
    }
    else {
        Write-Host ("Local branch already absent: {0}" -f $BranchName) -ForegroundColor Green
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run completed for merged branch cleanup." -ForegroundColor Green
    return
}

Write-Host ""
Write-Host "Merged branch cleanup completed." -ForegroundColor Green
& git branch --show-current
& git status
