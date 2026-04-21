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
$workflowPath = Join-Path $resolvedRepoRoot ".github\workflows\phase2-gate.yml"

if (-not (Test-Path $workflowPath)) {
    throw "Missing workflow surface at $workflowPath"
}

$workflowText = Get-Content $workflowPath -Raw
$failures = [System.Collections.ArrayList]::new()

foreach ($requiredPattern in @(
    'workflow_dispatch:',
    'contents:\s*read',
    'self-hosted',
    'windows',
    'eidonic-phase2',
    'actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5',
    'run_phase2_gate_with_capture\.ps1',
    'phase2_gate_output\.txt',
    'uses:\s*actions/upload-artifact@v4\.6\.2',
    'if:\s*always\(\)'
)) {
    if ($workflowText -notmatch $requiredPattern) {
        Add-Failure -Failures $failures -Message ("workflow missing required pattern '{0}'" -f $requiredPattern)
    }
}

if ($workflowText -match 'pull_request:' -or $workflowText -match 'push:') {
    Add-Failure -Failures $failures -Message "workflow trigger surface widened beyond workflow_dispatch"
}

$runStepIndex = $workflowText.IndexOf('Run Phase 2 gate with captured output')
$artifactStepIndex = $workflowText.IndexOf('Upload Phase 2 gate output artifact')

if ($runStepIndex -lt 0) {
    Add-Failure -Failures $failures -Message "workflow missing captured gate run step label"
}

if ($artifactStepIndex -lt 0) {
    Add-Failure -Failures $failures -Message "workflow missing gate output artifact upload step label"
}

if ($runStepIndex -ge 0 -and $artifactStepIndex -ge 0 -and $artifactStepIndex -lt $runStepIndex) {
    Add-Failure -Failures $failures -Message "artifact upload step appears before captured gate run step"
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    workflow_path = $workflowPath
    failures = @($failures)
}

Write-Host ""
Write-Host "Phase 2 workflow surface validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Phase 2 workflow surface validation failed."
}

Write-Host ""
Write-Host "Phase 2 workflow surface validation passed." -ForegroundColor Green
