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

$agentsPath = Join-Path $resolvedRepoRoot "AGENTS.md"
$codexConfigPath = Join-Path $resolvedRepoRoot ".codex\config.toml"
$branchSkillPath = Join-Path $resolvedRepoRoot ".agents\skills\phase2-branch-flow\SKILL.md"
$dependencySkillPath = Join-Path $resolvedRepoRoot ".agents\skills\phase2-dependency-wave\SKILL.md"
$codexWorkflowPath = Join-Path $resolvedRepoRoot "docs\CODEX_WORKFLOW.md"
$projectStatePath = Join-Path $resolvedRepoRoot "docs\PROJECT_STATE_AT_A_GLANCE.md"
$sessionLogPath = Join-Path $resolvedRepoRoot "docs\SESSION_LOG.md"

foreach ($requiredPath in @(
    $agentsPath,
    $codexConfigPath,
    $branchSkillPath,
    $dependencySkillPath,
    $codexWorkflowPath,
    $projectStatePath,
    $sessionLogPath
)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required Codex surface at $requiredPath"
    }
}

$failures = [System.Collections.ArrayList]::new()

$agentsText = Get-Content $agentsPath -Raw
foreach ($pattern in @(
    'docs/PROJECT_STATE_AT_A_GLANCE\.md',
    'docs/SESSION_LOG\.md',
    'config/service_topology_manifest\.json',
    'config/phase2_python_dependency_truth\.json',
    'scripts[\\/ ]run_phase2_gate\.ps1',
    'Do not claim completion without running the smallest relevant proof',
    'scripts[\\/ ]validate_codex_surfaces\.ps1'
)) {
    if ($agentsText -notmatch $pattern) {
        Add-Failure -Failures $failures -Message ("AGENTS.md missing required pattern '{0}'" -f $pattern)
    }
}

$codexConfigText = Get-Content $codexConfigPath -Raw
foreach ($pattern in @(
    'project_root_markers\s*=\s*\["\.git"\]',
    'approval_policy\s*=\s*"on-request"',
    '\[agents\]',
    'max_threads\s*=\s*2',
    'max_depth\s*=\s*1'
)) {
    if ($codexConfigText -notmatch $pattern) {
        Add-Failure -Failures $failures -Message (".codex/config.toml missing required pattern '{0}'" -f $pattern)
    }
}

$branchSkillText = Get-Content $branchSkillPath -Raw
foreach ($pattern in @(
    'name:\s*phase2-branch-flow',
    'description:',
    'docs/SESSION_LOG\.md',
    'docs/PROJECT_STATE_AT_A_GLANCE\.md',
    'scripts[\\/ ]run_phase2_gate\.ps1'
)) {
    if ($branchSkillText -notmatch $pattern) {
        Add-Failure -Failures $failures -Message ("phase2-branch-flow skill missing required pattern '{0}'" -f $pattern)
    }
}

$dependencySkillText = Get-Content $dependencySkillPath -Raw
foreach ($pattern in @(
    'name:\s*phase2-dependency-wave',
    'description:',
    'config/phase2_python_dependency_truth\.json',
    'scripts[\\/ ]sync_phase2_dependency_truth\.ps1',
    'scripts[\\/ ]validate_phase2_dependency_pins\.ps1',
    'scripts[\\/ ]absorb_phase2_dependency_wave\.ps1'
)) {
    if ($dependencySkillText -notmatch $pattern) {
        Add-Failure -Failures $failures -Message ("phase2-dependency-wave skill missing required pattern '{0}'" -f $pattern)
    }
}

$codexWorkflowText = Get-Content $codexWorkflowPath -Raw
foreach ($pattern in @(
    'AGENTS\.md',
    '\.codex/config\.toml',
    '\.agents/skills/',
    'Recovery rule for new chats',
    'scripts[\\/ ]validate_codex_surfaces\.ps1'
)) {
    if ($codexWorkflowText -notmatch $pattern) {
        Add-Failure -Failures $failures -Message ("docs/CODEX_WORKFLOW.md missing required pattern '{0}'" -f $pattern)
    }
}

$projectStateText = Get-Content $projectStatePath -Raw
foreach ($pattern in @(
    'AGENTS\.md',
    '\.codex/config\.toml',
    '\.agents/skills/phase2-branch-flow/SKILL\.md',
    '\.agents/skills/phase2-dependency-wave/SKILL\.md',
    'scripts[\\/ ]validate_codex_surfaces\.ps1'
)) {
    if ($projectStateText -notmatch $pattern) {
        Add-Failure -Failures $failures -Message ("docs/PROJECT_STATE_AT_A_GLANCE.md missing required pattern '{0}'" -f $pattern)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    codex_surfaces = @(
        $agentsPath,
        $codexConfigPath,
        $branchSkillPath,
        $dependencySkillPath,
        $codexWorkflowPath,
        $projectStatePath,
        $sessionLogPath
    )
    failures = @($failures)
}

Write-Host ""
Write-Host "Codex surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Codex surface validation failed."
}

Write-Host ""
Write-Host "Codex surface validation passed." -ForegroundColor Green
