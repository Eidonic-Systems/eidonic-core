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
$manifestPath = Join-Path $resolvedRepoRoot "config\recovery_surface_manifest.json"
$dependencyTruthPath = Join-Path $resolvedRepoRoot "config\phase2_python_dependency_truth.json"
$governanceManifestPath = Join-Path $resolvedRepoRoot "config\governance_rules_manifest.json"
$gateManifestPath = Join-Path $resolvedRepoRoot "config\phase2_gate_surface_manifest.json"
$projectStatePath = Join-Path $resolvedRepoRoot "docs\PROJECT_STATE_AT_A_GLANCE.md"

foreach ($requiredPath in @(
    $manifestPath,
    $dependencyTruthPath,
    $governanceManifestPath,
    $gateManifestPath,
    $projectStatePath
)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required truth surface at $requiredPath"
    }
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$dependencyTruth = Get-Content $dependencyTruthPath -Raw | ConvertFrom-Json
$governanceManifest = Get-Content $governanceManifestPath -Raw | ConvertFrom-Json
$gateManifest = Get-Content $gateManifestPath -Raw | ConvertFrom-Json
$surfaceChecks = @($manifest.authoritative_status_surface_checks)

if ($surfaceChecks.Count -eq 0) {
    throw "Recovery-surface manifest has no authoritative_status_surface_checks."
}

$failures = [System.Collections.ArrayList]::new()
$checkedSurfaces = [System.Collections.ArrayList]::new()

foreach ($surfaceCheck in $surfaceChecks) {
    $relativePath = [string]$surfaceCheck.path
    $requiredPatterns = @($surfaceCheck.required_patterns)

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        Add-Failure -Failures $failures -Message "authoritative status surface check missing path"
        continue
    }

    $absolutePath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        Add-Failure -Failures $failures -Message ("Missing required authoritative status surface at {0}" -f $absolutePath)
        continue
    }

    [void]$checkedSurfaces.Add($absolutePath)

    $surfaceText = Get-Content $absolutePath -Raw
    foreach ($pattern in $requiredPatterns) {
        $patternText = [string]$pattern
        if ($surfaceText -notmatch $patternText) {
            Add-Failure -Failures $failures -Message ("{0} missing required pattern '{1}'" -f $relativePath, $patternText)
        }
    }
}

$sharedPydanticPin = @($dependencyTruth.shared_package.required_dependency_pins | Where-Object { $_ -match '^pydantic==' })[0]
if ([string]::IsNullOrWhiteSpace([string]$sharedPydanticPin)) {
    Add-Failure -Failures $failures -Message "dependency truth is missing the shared pydantic pin"
}

$statusDocPath = Join-Path $resolvedRepoRoot "docs\PHASE_2_STATUS.md"
$milestoneDocPath = Join-Path $resolvedRepoRoot "docs\PHASE_2_MILESTONE_100_MERGED_PRS.md"
$orchestratorReadmePath = Join-Path $resolvedRepoRoot "services\eidon-orchestrator\README.md"

$statusText = Get-Content $statusDocPath -Raw
$milestoneText = Get-Content $milestoneDocPath -Raw
$orchestratorText = Get-Content $orchestratorReadmePath -Raw
$projectStateText = Get-Content $projectStatePath -Raw

if ($sharedPydanticPin) {
    if ($statusText -notmatch [regex]::Escape($sharedPydanticPin)) {
        Add-Failure -Failures $failures -Message ("docs/PHASE_2_STATUS.md missing current dependency truth pin '{0}'" -f $sharedPydanticPin)
    }

    if ($milestoneText -notmatch [regex]::Escape($sharedPydanticPin)) {
        Add-Failure -Failures $failures -Message ("docs/PHASE_2_MILESTONE_100_MERGED_PRS.md missing current dependency truth pin '{0}'" -f $sharedPydanticPin)
    }
}

$expectedGovernanceOutcomes = [System.Collections.ArrayList]::new()
foreach ($outcome in @(
    [string]$governanceManifest.default_success.governance_outcome
) + @($governanceManifest.rules | ForEach-Object { [string]$_.governance_outcome })) {
    if (-not [string]::IsNullOrWhiteSpace($outcome) -and $outcome -notin $expectedGovernanceOutcomes) {
        [void]$expectedGovernanceOutcomes.Add($outcome)
    }
}

foreach ($outcome in @($expectedGovernanceOutcomes)) {
    $quotedOutcomePattern = [regex]::Escape(([char]96 + $outcome + [char]96))

    if ($statusText -notmatch $quotedOutcomePattern) {
        Add-Failure -Failures $failures -Message ("docs/PHASE_2_STATUS.md missing governance outcome '{0}' from manifest-backed truth" -f $outcome)
    }

    if ($orchestratorText -notmatch $quotedOutcomePattern) {
        Add-Failure -Failures $failures -Message ("services/eidon-orchestrator/README.md missing governance outcome '{0}' from manifest-backed truth" -f $outcome)
    }
}

$authoritativeStatusGateIntegrated = @(
    $gateManifest.validation_steps |
    Where-Object { $_.script_path -eq 'scripts/validate_authoritative_status_surfaces.ps1' }
).Count -gt 0

if ($authoritativeStatusGateIntegrated) {
    $requiredOperatorGateLine = 'project-state, session-log, untracked-file, scripts-README, root-doc, and authoritative-status surfaces before downstream runtime checks'
    if ($projectStateText -notmatch [regex]::Escape($requiredOperatorGateLine)) {
        Add-Failure -Failures $failures -Message "docs/PROJECT_STATE_AT_A_GLANCE.md does not reflect the current operator-surface gate posture"
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    recovery_surface_manifest_path = $manifestPath
    dependency_truth_path = $dependencyTruthPath
    governance_manifest_path = $governanceManifestPath
    gate_manifest_path = $gateManifestPath
    checked_surface_count = $checkedSurfaces.Count
    checked_surfaces = @($checkedSurfaces)
    shared_pydantic_pin = [string]$sharedPydanticPin
    expected_governance_outcomes = @($expectedGovernanceOutcomes)
    failures = @($failures)
}

Write-Host ""
Write-Host "Authoritative-status surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Authoritative-status surface validation failed."
}

Write-Host ""
Write-Host "Authoritative-status surface validation passed." -ForegroundColor Green
