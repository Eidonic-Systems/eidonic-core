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

function Get-EnvValue {
    param(
        [string]$Path,
        [string]$Key
    )

    $match = Select-String -Path $Path -Pattern ("^{0}=(.+)$" -f [regex]::Escape($Key))
    if ($null -eq $match) {
        return $null
    }

    return $match.Matches[0].Groups[1].Value.Trim()
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\service_topology_manifest.json"
$envExamplePath = Join-Path $resolvedRepoRoot ".env.example"
$testsReadmePath = Join-Path $resolvedRepoRoot "tests\README.md"

if (-not (Test-Path $manifestPath)) {
    throw "Missing service topology manifest at $manifestPath"
}
if (-not (Test-Path $envExamplePath)) {
    throw "Missing .env.example at $envExamplePath"
}
if (-not (Test-Path $testsReadmePath)) {
    throw "Missing tests README at $testsReadmePath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$services = @($manifest.services)

$expected = @{}
foreach ($service in $services) {
    $expected[[string]$service.name] = [int]$service.port
}

$failures = [System.Collections.ArrayList]::new()

if (-not $expected.ContainsKey("session-engine")) {
    Add-Failure -Failures $failures -Message "topology manifest missing session-engine"
}
if (-not $expected.ContainsKey("herald-service")) {
    Add-Failure -Failures $failures -Message "topology manifest missing herald-service"
}

$sessionExpected = $expected["session-engine"]
$heraldExpected = $expected["herald-service"]

$sessionEnv = Get-EnvValue -Path $envExamplePath -Key "SESSION_ENGINE_BASE_URL"
$heraldEnv = Get-EnvValue -Path $envExamplePath -Key "HERALD_BASE_URL"

if ($null -eq $sessionEnv) {
    Add-Failure -Failures $failures -Message ".env.example missing SESSION_ENGINE_BASE_URL"
}
elseif ($sessionEnv -notmatch (":{0}$" -f $sessionExpected)) {
    Add-Failure -Failures $failures -Message ".env.example SESSION_ENGINE_BASE_URL does not match topology port $sessionExpected"
}

if ($null -eq $heraldEnv) {
    Add-Failure -Failures $failures -Message ".env.example missing HERALD_BASE_URL"
}
elseif ($heraldEnv -notmatch (":{0}$" -f $heraldExpected)) {
    Add-Failure -Failures $failures -Message ".env.example HERALD_BASE_URL does not match topology port $heraldExpected"
}

$testsReadme = Get-Content $testsReadmePath -Raw

$sessionPattern = "(?is)session-engine.*?{0}" -f $sessionExpected
$heraldPattern = "(?is)herald-service.*?{0}" -f $heraldExpected

if ($testsReadme -notmatch $sessionPattern) {
    Add-Failure -Failures $failures -Message "tests/README.md does not reflect session-engine port $sessionExpected"
}

if ($testsReadme -notmatch $heraldPattern) {
    Add-Failure -Failures $failures -Message "tests/README.md does not reflect herald-service port $heraldExpected"
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    env_example_path = $envExamplePath
    tests_readme_path = $testsReadmePath
    expected_ports = @{
        "session-engine" = $sessionExpected
        "herald-service" = $heraldExpected
    }
    failures = @($failures)
}

Write-Host ""
Write-Host "Phase 2 topology consistency validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Phase 2 topology consistency validation failed."
}

Write-Host ""
Write-Host "Phase 2 topology consistency validation passed." -ForegroundColor Green
