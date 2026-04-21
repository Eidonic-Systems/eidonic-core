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

Run-GitStep -Label "Switching to main" -GitArgs @("switch", "main")
Run-GitStep -Label "Pulling latest main" -GitArgs @("pull", "--ff-only")
Run-GitStep -Label "Pruning remote refs" -GitArgs @("fetch", "--prune")
Run-GitStep -Label "Showing repo status" -GitArgs @("status")

foreach ($tempFile in $TempFiles) {
    $tempPath = Join-Path $RepoRoot $tempFile

    if ($DryRun) {
        Write-Host ("[DRY-RUN] remove-item {0}" -f $tempPath) -ForegroundColor Cyan
        continue
    }

    Remove-Item $tempPath -ErrorAction SilentlyContinue
}

$deleteFlag = if ($ForceDelete) { "-D" } else { "-d" }
Run-GitStep -Label ("Deleting local branch {0}" -f $BranchName) -GitArgs @("branch", $deleteFlag, $BranchName)

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run completed for merged branch cleanup." -ForegroundColor Green
    return
}

Write-Host ""
Write-Host "Merged branch cleanup completed." -ForegroundColor Green
& git branch --show-current
& git status
