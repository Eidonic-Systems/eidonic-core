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

function Write-Section {
    param(
        [string]$Label
    )

    Write-Host ""
    Write-Host ("==> {0}" -f $Label) -ForegroundColor Yellow
}

function Get-StatusSnapshot {
    $statusText = (& git status --short | Out-String)
    return @(
        $statusText -split "(`r`n|`n|`r)" |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.TrimEnd() }
    )
}

function Status-SnapshotsMatch {
    param(
        [string[]]$Before,
        [string[]]$After
    )

    if ($Before.Count -ne $After.Count) {
        return $false
    }

    for ($i = 0; $i -lt $Before.Count; $i++) {
        if ($Before[$i] -ne $After[$i]) {
            return $false
        }
    }

    return $true
}

function Invoke-Helper {
    param(
        [string]$Label,
        [string[]]$PowerShellArgs
    )

    Write-Section -Label $Label
    $output = (& powershell @PowerShellArgs 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE

    [pscustomobject]@{
        label = $Label
        exit_code = $exitCode
        output = $output.TrimEnd()
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
Set-Location $resolvedRepoRoot

$gitIgnorePath = Join-Path $resolvedRepoRoot ".gitignore"
$startHelperPath = Join-Path $resolvedRepoRoot "scripts\start_bounded_branch.ps1"
$finishHelperPath = Join-Path $resolvedRepoRoot "scripts\finish_merged_branch.ps1"
$gateWrapperPath = Join-Path $resolvedRepoRoot "scripts\run_phase2_gate_with_capture.ps1"
$sessionLogHelperPath = Join-Path $resolvedRepoRoot "scripts\append_session_log_entry.ps1"
$syncHelperPath = Join-Path $resolvedRepoRoot "scripts\sync_phase2_dependency_truth.ps1"
$waveHelperPath = Join-Path $resolvedRepoRoot "scripts\absorb_phase2_dependency_wave.ps1"
$truthPath = Join-Path $resolvedRepoRoot "config\phase2_python_dependency_truth.json"

foreach ($requiredPath in @(
    $gitIgnorePath,
    $startHelperPath,
    $finishHelperPath,
    $gateWrapperPath,
    $sessionLogHelperPath,
    $syncHelperPath,
    $waveHelperPath,
    $truthPath
)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required automation helper surface at $requiredPath"
    }
}

$failures = [System.Collections.ArrayList]::new()
$results = [System.Collections.ArrayList]::new()

Write-Section -Label "Checking static finish-helper guard placement"
$finishHelperText = Get-Content $finishHelperPath -Raw
$dirtyGuardIndex = $finishHelperText.IndexOf("Working tree is dirty. Refusing merged-branch cleanup before pull.")
$switchMainIndex = $finishHelperText.IndexOf('Run-GitStep -Label "Switching to main"')
$alreadyAbsentIndex = $finishHelperText.IndexOf("Local branch already absent:")
$preCleanIndex = $finishHelperText.IndexOf("==> Pre-cleaning known temp output files")

if ($dirtyGuardIndex -lt 0) {
    Add-Failure -Failures $failures -Message "finish_merged_branch.ps1 missing dirty-tree refusal message"
}
if ($switchMainIndex -lt 0) {
    Add-Failure -Failures $failures -Message "finish_merged_branch.ps1 missing switch-to-main step"
}
if ($dirtyGuardIndex -ge 0 -and $switchMainIndex -ge 0 -and $dirtyGuardIndex -gt $switchMainIndex) {
    Add-Failure -Failures $failures -Message "finish_merged_branch.ps1 dirty-tree refusal appears after switch-to-main step"
}
if ($alreadyAbsentIndex -lt 0) {
    Add-Failure -Failures $failures -Message "finish_merged_branch.ps1 missing already-absent branch handling"
}
if ($preCleanIndex -lt 0) {
    Add-Failure -Failures $failures -Message "finish_merged_branch.ps1 missing pre-clean temp file step"
}

Write-Section -Label "Checking gitignore coverage for local proof artifacts"
$gitIgnoreText = Get-Content $gitIgnorePath -Raw
foreach ($pattern in @('tmp_phase2_gate_output.txt', 'tmp_test_full_chain_output.txt')) {
    if ($gitIgnoreText -notmatch [regex]::Escape($pattern)) {
        Add-Failure -Failures $failures -Message (".gitignore missing local proof artifact pattern '{0}'" -f $pattern)
    }
}

$baselineStatus = Get-StatusSnapshot

Write-Section -Label "Checking ignored temp artifact behavior"
$tempArtifactPaths = @(
    (Join-Path $resolvedRepoRoot "tmp_phase2_gate_output.txt"),
    (Join-Path $resolvedRepoRoot "tmp_test_full_chain_output.txt")
)

try {
    foreach ($tempArtifactPath in $tempArtifactPaths) {
        Set-Content -Path $tempArtifactPath -Value "automation-helper-validation" -NoNewline
    }

    $statusWithTempArtifacts = Get-StatusSnapshot
    if (-not (Status-SnapshotsMatch -Before $baselineStatus -After $statusWithTempArtifacts)) {
        Add-Failure -Failures $failures -Message "ignored temp proof artifacts changed git status"
    }
}
finally {
    foreach ($tempArtifactPath in $tempArtifactPaths) {
        Remove-Item $tempArtifactPath -Force -ErrorAction SilentlyContinue
    }
}

$afterTempArtifactCleanupStatus = Get-StatusSnapshot
if (-not (Status-SnapshotsMatch -Before $baselineStatus -After $afterTempArtifactCleanupStatus)) {
    Add-Failure -Failures $failures -Message "temp artifact cleanup did not restore original git status snapshot"
}

$startResult = Invoke-Helper -Label "Dry-run start bounded branch helper" -PowerShellArgs @(
    "-ExecutionPolicy", "Bypass",
    "-File", $startHelperPath,
    "-BranchName", "phase-2/example-branch",
    "-DryRun"
)
[void]$results.Add($startResult)
if ($startResult.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message "start_bounded_branch.ps1 dry-run failed"
}
foreach ($pattern in @('git switch main', 'git pull --ff-only', 'git switch -c phase-2/example-branch')) {
    if ($startResult.output -notmatch [regex]::Escape($pattern)) {
        Add-Failure -Failures $failures -Message ("start_bounded_branch.ps1 dry-run missing pattern '{0}'" -f $pattern)
    }
}

$finishResult = Invoke-Helper -Label "Dry-run finish merged branch helper" -PowerShellArgs @(
    "-ExecutionPolicy", "Bypass",
    "-File", $finishHelperPath,
    "-BranchName", "phase-2/example-branch",
    "-DryRun"
)
[void]$results.Add($finishResult)
if ($finishResult.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message "finish_merged_branch.ps1 dry-run failed"
}
foreach ($pattern in @(
    'remove-item',
    'tmp_phase2_gate_output.txt',
    'tmp_test_full_chain_output.txt',
    'git switch main',
    'git pull --ff-only',
    'idempotent cleanup supports already-absent branch'
)) {
    if ($finishResult.output -notmatch [regex]::Escape($pattern)) {
        Add-Failure -Failures $failures -Message ("finish_merged_branch.ps1 dry-run missing pattern '{0}'" -f $pattern)
    }
}

$gateResult = Invoke-Helper -Label "Dry-run captured gate helper" -PowerShellArgs @(
    "-ExecutionPolicy", "Bypass",
    "-File", $gateWrapperPath,
    "-DryRun"
)
[void]$results.Add($gateResult)
if ($gateResult.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message "run_phase2_gate_with_capture.ps1 dry-run failed"
}
foreach ($pattern in @('run_phase2_gate.ps1', 'tmp_phase2_gate_output.txt')) {
    if ($gateResult.output -notmatch [regex]::Escape($pattern)) {
        Add-Failure -Failures $failures -Message ("run_phase2_gate_with_capture.ps1 dry-run missing pattern '{0}'" -f $pattern)
    }
}

$sessionResult = Invoke-Helper -Label "Dry-run session log helper" -PowerShellArgs @(
    "-ExecutionPolicy", "Bypass",
    "-File", $sessionLogHelperPath,
    "-BranchName", "phase-2/example-branch",
    "-NotesText", "First note.`nSecond note.",
    "-DryRun"
)
[void]$results.Add($sessionResult)
if ($sessionResult.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message "append_session_log_entry.ps1 dry-run failed"
}
foreach ($pattern in @('First note.', 'Second note.')) {
    if ($sessionResult.output -notmatch [regex]::Escape($pattern)) {
        Add-Failure -Failures $failures -Message ("append_session_log_entry.ps1 dry-run missing pattern '{0}'" -f $pattern)
    }
}

$syncResult = Invoke-Helper -Label "Dry-run dependency truth sync helper" -PowerShellArgs @(
    "-ExecutionPolicy", "Bypass",
    "-File", $syncHelperPath,
    "-RepoRoot", $resolvedRepoRoot,
    "-DryRun"
)
[void]$results.Add($syncResult)
if ($syncResult.exit_code -ne 0) {
    Add-Failure -Failures $failures -Message "sync_phase2_dependency_truth.ps1 dry-run failed"
}

$truth = Get-Content $truthPath -Raw | ConvertFrom-Json
$currentPydanticPin = @($truth.shared_package.required_dependency_pins | Where-Object { $_ -match '^pydantic==' }) | Select-Object -First 1
if ([string]::IsNullOrWhiteSpace([string]$currentPydanticPin)) {
    Add-Failure -Failures $failures -Message "dependency truth missing shared pydantic pin"
}
else {
    $currentPydanticVersion = ($currentPydanticPin -split '==', 2)[1]

    $noOpWaveResult = Invoke-Helper -Label "No-op dependency wave execution" -PowerShellArgs @(
        "-ExecutionPolicy", "Bypass",
        "-File", $waveHelperPath,
        "-PackageName", "pydantic",
        "-NewVersion", $currentPydanticVersion,
        "-ExpectedCurrentVersion", $currentPydanticVersion
    )
    [void]$results.Add($noOpWaveResult)

    if ($noOpWaveResult.exit_code -ne 0) {
        Add-Failure -Failures $failures -Message "absorb_phase2_dependency_wave.ps1 no-op execution failed"
    }

    if ($noOpWaveResult.output -notmatch [regex]::Escape("Dependency truth already at approved version")) {
        Add-Failure -Failures $failures -Message "absorb_phase2_dependency_wave.ps1 no-op execution did not report approved-version alignment"
    }

    $afterStatus = Get-StatusSnapshot
    if (-not (Status-SnapshotsMatch -Before $baselineStatus -After $afterStatus)) {
        Add-Failure -Failures $failures -Message "automation helper validation changed git status during no-op dependency wave execution"
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    repo_root = $resolvedRepoRoot
    checked_helpers = @(
        "scripts/start_bounded_branch.ps1",
        "scripts/finish_merged_branch.ps1",
        "scripts/run_phase2_gate_with_capture.ps1",
        "scripts/append_session_log_entry.ps1",
        "scripts/sync_phase2_dependency_truth.ps1",
        "scripts/absorb_phase2_dependency_wave.ps1"
    )
    results = $results
    failures = @($failures)
}

Write-Host ""
Write-Host "Automation helper validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne "passed") {
    throw "Automation helper validation failed."
}

Write-Host ""
Write-Host "Automation helper validation passed." -ForegroundColor Green
