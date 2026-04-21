param(
    [string]$OutputPath = "tmp_phase2_gate_output.txt",
    [switch]$SkipStackStart,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

$resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $RepoRoot $OutputPath
}

$gateArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $RepoRoot "scripts\run_phase2_gate.ps1")
)

if ($SkipStackStart) {
    $gateArgs += "-SkipStackStart"
}

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run for captured Phase 2 gate wrapper:" -ForegroundColor Yellow
    Write-Host ("powershell {0} *> {1}" -f ($gateArgs -join " "), $resolvedOutputPath) -ForegroundColor Cyan
    return
}

& powershell @gateArgs *> $resolvedOutputPath
$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host ("Captured Phase 2 gate output at {0}" -f $resolvedOutputPath) -ForegroundColor Yellow
Get-Content $resolvedOutputPath -Tail 80

if ($exitCode -ne 0) {
    exit $exitCode
}

Write-Host ""
Write-Host "Captured Phase 2 gate run completed." -ForegroundColor Green
