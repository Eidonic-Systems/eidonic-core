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
$projectStatePath = Join-Path $resolvedRepoRoot "docs\PROJECT_STATE_AT_A_GLANCE.md"

if (-not (Test-Path $projectStatePath)) {
    throw "Missing project-state surface at $projectStatePath"
}

$requiredTruthSurfaces = @(
    "config/service_topology_manifest.json",
    "config/phase2_python_dependency_truth.json",
    "config/phase2_gate_surface_manifest.json",
    "scripts/run_phase2_gate.ps1",
    "scripts/validate_phase2_gate_surface_manifest.ps1",
    "config/governance_rules_manifest.json",
    ".github/workflows/phase2-gate.yml",
    "docs/PHASE_2_RUNNER_TRUST_CONTRACT.md",
    "AGENTS.md",
    ".codex/config.toml",
    ".agents/skills/phase2-branch-flow/SKILL.md",
    ".agents/skills/phase2-dependency-wave/SKILL.md",
    "docs/CODEX_WORKFLOW.md",
    "docs/SESSION_LOG.md",
    "scripts/validate_automation_helpers.ps1",
    "scripts/validate_phase2_workflow_surface.ps1",
    "scripts/validate_codex_surfaces.ps1",
    "scripts/validate_project_state_surface.ps1"
)

foreach ($relativePath in $requiredTruthSurfaces) {
    $absolutePath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $absolutePath)) {
        throw "Missing required truth surface on disk: $relativePath"
    }
}

$projectStateText = Get-Content $projectStatePath -Raw
$failures = [System.Collections.ArrayList]::new()

foreach ($relativePath in $requiredTruthSurfaces) {
    $escapedForward = [regex]::Escape($relativePath)
    $backslashPath = $relativePath.Replace("/", "\")
    $escapedBackslash = [regex]::Escape($backslashPath)

    if (($projectStateText -notmatch $escapedForward) -and ($projectStateText -notmatch $escapedBackslash)) {
        Add-Failure -Failures $failures -Message ("project-state surface missing truth reference '{0}'" -f $relativePath)
    }
}

foreach ($requiredPattern in @(
    '## Current gate posture',
    '## Current governance posture',
    '## Current runner posture',
    '## Current repo-memory surfaces',
    '## Current project-state validation surface'
)) {
    if ($projectStateText -notmatch [regex]::Escape($requiredPattern)) {
        Add-Failure -Failures $failures -Message ("project-state surface missing required section heading '{0}'" -f $requiredPattern)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    project_state_path = $projectStatePath
    required_truth_surface_count = $requiredTruthSurfaces.Count
    failures = @($failures)
}

Write-Host ""
Write-Host "Project-state surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Project-state surface validation failed."
}

Write-Host ""
Write-Host "Project-state surface validation passed." -ForegroundColor Green
