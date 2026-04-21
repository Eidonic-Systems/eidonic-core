param(
    [string]$OutputPath,
    [switch]$SkipStackStart,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

function Get-DefaultOutputPath {
    param(
        [string]$RootPath
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
    $fileName = "tmp_phase2_gate_output_{0}_{1}.txt" -f $timestamp, $PID
    return (Join-Path $RootPath $fileName)
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $resolvedOutputPath = Get-DefaultOutputPath -RootPath $RepoRoot
    $usingGeneratedPath = $true
}
elseif ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $resolvedOutputPath = $OutputPath
    $usingGeneratedPath = $false
}
else {
    $resolvedOutputPath = Join-Path $RepoRoot $OutputPath
    $usingGeneratedPath = $false
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

if ((-not $usingGeneratedPath) -and (Test-Path $resolvedOutputPath)) {
    try {
        Remove-Item $resolvedOutputPath -Force -ErrorAction Stop
    }
    catch {
        throw ("Could not clear existing output file before captured gate run: {0}" -f $resolvedOutputPath)
    }
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
