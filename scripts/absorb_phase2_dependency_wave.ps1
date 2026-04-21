param(
    [string]$RepoRoot = ".",
    [Parameter(Mandatory = $true)]
    [string]$PackageName,
    [Parameter(Mandatory = $true)]
    [string]$NewVersion,
    [string]$ExpectedCurrentVersion,
    [switch]$RunGate,
    [switch]$SkipStackStart,
    [switch]$AppendSessionLog,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param(
        [string]$Label
    )

    Write-Host ""
    Write-Host ("==> {0}" -f $Label) -ForegroundColor Yellow
}

function Require-Path {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Missing required path: $Path"
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$truthPath = Join-Path $resolvedRepoRoot "config\phase2_python_dependency_truth.json"
$syncScriptPath = Join-Path $resolvedRepoRoot "scripts\sync_phase2_dependency_truth.ps1"
$validateScriptPath = Join-Path $resolvedRepoRoot "scripts\validate_phase2_dependency_pins.ps1"
$gateWrapperPath = Join-Path $resolvedRepoRoot "scripts\run_phase2_gate_with_capture.ps1"
$sessionLogHelperPath = Join-Path $resolvedRepoRoot "scripts\append_session_log_entry.ps1"

Require-Path $truthPath
Require-Path $syncScriptPath
Require-Path $validateScriptPath
Require-Path $gateWrapperPath
Require-Path $sessionLogHelperPath

$truthText = Get-Content $truthPath -Raw
$truth = $truthText | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace([string]$truth.manifest_version)) {
    throw "Dependency truth file missing manifest_version."
}

$serviceRequirements = @($truth.service_requirements)
if ($serviceRequirements.Count -eq 0) {
    throw "Dependency truth file has no service_requirements."
}

$packagePattern = ('^{0}==(.*)$' -f [regex]::Escape($PackageName))
$replacementPin = ('{0}=={1}' -f $PackageName, $NewVersion)

$serviceUpdateCount = 0
$sharedUpdateCount = 0
$affectedServices = [System.Collections.ArrayList]::new()
$pinsToReplace = [System.Collections.ArrayList]::new()

Write-Section -Label ("Updating dependency truth for {0}" -f $PackageName)

foreach ($entry in $serviceRequirements) {
    $serviceName = [string]$entry.service
    $requiredPins = @($entry.required_pins)

    for ($i = 0; $i -lt $requiredPins.Count; $i++) {
        $pin = [string]$requiredPins[$i]
        if ($pin -notmatch $packagePattern) {
            continue
        }

        $currentVersion = $Matches[1]

        if (-not [string]::IsNullOrWhiteSpace($ExpectedCurrentVersion) -and $currentVersion -ne $ExpectedCurrentVersion) {
            throw ("Service '{0}' has {1}, expected current version {2}." -f $serviceName, $pin, $ExpectedCurrentVersion)
        }

        if ($currentVersion -ne $NewVersion) {
            $entry.required_pins[$i] = $replacementPin
            $serviceUpdateCount++
            if ($pin -notin $pinsToReplace) {
                [void]$pinsToReplace.Add($pin)
            }
        }

        if ($serviceName -notin $affectedServices) {
            [void]$affectedServices.Add($serviceName)
        }
    }
}

$sharedPackage = $truth.shared_package
if ($null -eq $sharedPackage) {
    throw "Dependency truth file missing shared_package section."
}

$sharedPins = @($sharedPackage.required_dependency_pins)
for ($i = 0; $i -lt $sharedPins.Count; $i++) {
    $pin = [string]$sharedPins[$i]
    if ($pin -notmatch $packagePattern) {
        continue
    }

    $currentVersion = $Matches[1]

    if (-not [string]::IsNullOrWhiteSpace($ExpectedCurrentVersion) -and $currentVersion -ne $ExpectedCurrentVersion) {
        throw ("Shared package has {0}, expected current version {1}." -f $pin, $ExpectedCurrentVersion)
    }

    if ($currentVersion -ne $NewVersion) {
        $sharedPackage.required_dependency_pins[$i] = $replacementPin
        $sharedUpdateCount++
        if ($pin -notin $pinsToReplace) {
            [void]$pinsToReplace.Add($pin)
        }
    }
}

$summary = [ordered]@{
    package = $PackageName
    approved_version = $NewVersion
    expected_current_version = $ExpectedCurrentVersion
    affected_services = @($affectedServices)
    service_updates = $serviceUpdateCount
    shared_package_updates = $sharedUpdateCount
    dry_run = [bool]$DryRun
}

Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($DryRun) {
    if (($serviceUpdateCount + $sharedUpdateCount) -eq 0) {
        Write-Host ""
        Write-Host "[DRY-RUN] dependency truth already at approved version. No truth-file rewrite needed." -ForegroundColor Cyan
    }
    else {
        Write-Host ""
        Write-Host ("[DRY-RUN] would update dependency truth file at {0}" -f $truthPath) -ForegroundColor Cyan
    }
}
else {
    if (($serviceUpdateCount + $sharedUpdateCount) -eq 0) {
        Write-Host ("Dependency truth already at approved version in {0}" -f $truthPath) -ForegroundColor Green
    }
    else {
        foreach ($oldPin in $pinsToReplace) {
            $pattern = ('"{0}"' -f [regex]::Escape($oldPin))
            $replacement = ('"{0}"' -f $replacementPin)
            $truthText = [regex]::Replace($truthText, $pattern, $replacement)
        }

        Set-Content $truthPath $truthText -NoNewline
        Write-Host ("Updated dependency truth file at {0}" -f $truthPath) -ForegroundColor Green
    }
}

Write-Section -Label "Syncing dependency truth to dependent files"

$syncArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $syncScriptPath,
    "-RepoRoot", $resolvedRepoRoot
)

if ($DryRun) {
    $syncArgs += "-DryRun"
}

& powershell @syncArgs
if ($LASTEXITCODE -ne 0) {
    throw "Dependency truth sync failed."
}

Write-Section -Label "Validating dependency pins"

if (-not $DryRun) {
    & powershell -ExecutionPolicy Bypass -File $validateScriptPath -RepoRoot $resolvedRepoRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Dependency pin validation failed."
    }
}
else {
    Write-Host "[DRY-RUN] would run dependency pin validation" -ForegroundColor Cyan
}

if ($RunGate) {
    Write-Section -Label "Running Phase 2 gate with capture"

    $gateArgs = @(
        "-ExecutionPolicy", "Bypass",
        "-File", $gateWrapperPath
    )

    if ($SkipStackStart) {
        $gateArgs += "-SkipStackStart"
    }

    if ($DryRun) {
        $gateArgs += "-DryRun"
    }

    & powershell @gateArgs
    if (-not $DryRun -and $LASTEXITCODE -ne 0) {
        throw "Phase 2 gate wrapper failed."
    }
}

if ($AppendSessionLog) {
    Write-Section -Label "Appending session log entry"

    $notes = @(
        ("Coordinated dependency wave automation updated `{0}` to `{1}` through the dependency truth source." -f $PackageName, $NewVersion),
        "Synced dependent files from `config/phase2_python_dependency_truth.json` and re-ran dependency validation."
    )

    & powershell -ExecutionPolicy Bypass -File $sessionLogHelperPath -BranchName ("phase-2/{0}-{1}-wave" -f $PackageName, ($NewVersion -replace '\.', '-')) -NotesText ($notes -join "`n")
    if ($LASTEXITCODE -ne 0) {
        throw "Session log append failed."
    }
}

Write-Host ""
Write-Host "Phase 2 dependency wave automation completed." -ForegroundColor Green

