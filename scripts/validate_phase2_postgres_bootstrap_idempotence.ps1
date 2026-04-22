param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Invoke-CheckedPowerShell {
    param(
        [string]$Label,
        [string]$ScriptPath,
        [string]$RepoRootPath
    )

    Write-Host ""
    Write-Host ("==> {0}" -f $Label) -ForegroundColor Yellow

    $output = & powershell -ExecutionPolicy Bypass -File $ScriptPath -RepoRoot $RepoRootPath 2>&1
    $exitCode = $LASTEXITCODE

    $text = ($output | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($text)) {
        Write-Host $text
    }

    if ($exitCode -ne 0) {
        throw ("{0} failed with exit code {1}." -f $Label, $exitCode)
    }

    return $text
}

function Get-JsonBlockFromOutput {
    param(
        [string]$Text
    )

    $match = [regex]::Match($Text, '\{[\s\S]*\}')
    if (-not $match.Success) {
        throw "Could not find JSON summary block in script output."
    }

    return ($match.Value | ConvertFrom-Json)
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path

$bootstrapScript = Join-Path $resolvedRepoRoot 'scripts\bootstrap_phase2_postgres.ps1'
$schemaBootstrapScript = Join-Path $resolvedRepoRoot 'scripts\bootstrap_phase2_postgres_schema.ps1'
$schemaDriftScript = Join-Path $resolvedRepoRoot 'scripts\validate_phase2_postgres_schema_drift.ps1'

foreach ($requiredPath in @(
    $bootstrapScript,
    $schemaBootstrapScript,
    $schemaDriftScript
)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required PostgreSQL proof surface at $requiredPath"
    }
}

$firstBootstrapText = Invoke-CheckedPowerShell -Label 'First Phase 2 PostgreSQL bootstrap run' -ScriptPath $bootstrapScript -RepoRootPath $resolvedRepoRoot
$firstBootstrapSummary = Get-JsonBlockFromOutput -Text $firstBootstrapText

$secondBootstrapText = Invoke-CheckedPowerShell -Label 'Second Phase 2 PostgreSQL bootstrap run' -ScriptPath $bootstrapScript -RepoRootPath $resolvedRepoRoot
$secondBootstrapSummary = Get-JsonBlockFromOutput -Text $secondBootstrapText

$firstSchemaBootstrapText = Invoke-CheckedPowerShell -Label 'First Phase 2 PostgreSQL schema bootstrap run' -ScriptPath $schemaBootstrapScript -RepoRootPath $resolvedRepoRoot
$firstSchemaBootstrapSummary = Get-JsonBlockFromOutput -Text $firstSchemaBootstrapText

$secondSchemaBootstrapText = Invoke-CheckedPowerShell -Label 'Second Phase 2 PostgreSQL schema bootstrap run' -ScriptPath $schemaBootstrapScript -RepoRootPath $resolvedRepoRoot
$secondSchemaBootstrapSummary = Get-JsonBlockFromOutput -Text $secondSchemaBootstrapText

$schemaDriftText = Invoke-CheckedPowerShell -Label 'Phase 2 PostgreSQL schema drift validation after repeated bootstrap' -ScriptPath $schemaDriftScript -RepoRootPath $resolvedRepoRoot
$schemaDriftSummary = Get-JsonBlockFromOutput -Text $schemaDriftText

$failures = [System.Collections.ArrayList]::new()

if ([string]$firstBootstrapSummary.status -ne 'passed') {
    [void]$failures.Add("first database bootstrap run did not pass")
}

if ([string]$secondBootstrapSummary.status -ne 'passed') {
    [void]$failures.Add("second database bootstrap run did not pass")
}

if ([string]$secondBootstrapSummary.action -ne 'already_exists') {
    [void]$failures.Add("second database bootstrap run did not settle to already_exists")
}

if ([string]$firstSchemaBootstrapSummary.status -ne 'passed') {
    [void]$failures.Add("first schema bootstrap run did not pass")
}

if ([string]$secondSchemaBootstrapSummary.status -ne 'passed') {
    [void]$failures.Add("second schema bootstrap run did not pass")
}

if ([string]$firstSchemaBootstrapSummary.artifact_table -ne 'artifact_records') {
    [void]$failures.Add("first schema bootstrap run did not verify artifact_records")
}

if ([string]$firstSchemaBootstrapSummary.lineage_table -ne 'artifact_lineage_records') {
    [void]$failures.Add("first schema bootstrap run did not verify artifact_lineage_records")
}

if ([string]$secondSchemaBootstrapSummary.artifact_table -ne 'artifact_records') {
    [void]$failures.Add("second schema bootstrap run did not verify artifact_records")
}

if ([string]$secondSchemaBootstrapSummary.lineage_table -ne 'artifact_lineage_records') {
    [void]$failures.Add("second schema bootstrap run did not verify artifact_lineage_records")
}

if ([string]$schemaDriftSummary.status -ne 'passed') {
    [void]$failures.Add("schema drift validation did not pass after repeated bootstrap")
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { 'passed' } else { 'failed' })
    database_bootstrap_first_action = [string]$firstBootstrapSummary.action
    database_bootstrap_second_action = [string]$secondBootstrapSummary.action
    schema_bootstrap_first_status = [string]$firstSchemaBootstrapSummary.status
    schema_bootstrap_second_status = [string]$secondSchemaBootstrapSummary.status
    schema_drift_status = [string]$schemaDriftSummary.status
    failures = @($failures)
}

Write-Host ""
Write-Host "Phase 2 PostgreSQL bootstrap idempotence validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne 'passed') {
    throw "Phase 2 PostgreSQL bootstrap idempotence validation failed."
}

Write-Host ""
Write-Host "Phase 2 PostgreSQL bootstrap idempotence validation passed." -ForegroundColor Green
