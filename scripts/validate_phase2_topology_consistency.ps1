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

function Test-DocumentContainsServicePort {
    param(
        [string]$Content,
        [string]$ServiceName,
        [int]$Port
    )

    $escapedName = [regex]::Escape($ServiceName)
    $escapedPort = [regex]::Escape([string]$Port)

    return (
        $Content -match ("(?is){0}.*?{1}" -f $escapedName, $escapedPort) -or
        $Content -match ("(?is){0}.*?{1}" -f $escapedPort, $escapedName)
    )
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\service_topology_manifest.json"
$envExamplePath = Join-Path $resolvedRepoRoot ".env.example"
$testsReadmePath = Join-Path $resolvedRepoRoot "tests\README.md"
$startScriptPath = Join-Path $resolvedRepoRoot "scripts\start_phase_2_stack.ps1"
$scriptsReadmePath = Join-Path $resolvedRepoRoot "scripts\README.md"
$signalGatewayMainPath = Join-Path $resolvedRepoRoot "services\signal-gateway\app\main.py"
$fullChainTestPath = Join-Path $resolvedRepoRoot "tests\integration\test_full_chain.ps1"

foreach ($requiredPath in @(
    $manifestPath,
    $envExamplePath,
    $testsReadmePath,
    $startScriptPath,
    $scriptsReadmePath,
    $signalGatewayMainPath,
    $fullChainTestPath
)) {
    if (-not (Test-Path $requiredPath)) {
        throw "Missing required topology surface at $requiredPath"
    }
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$services = @($manifest.services)

if ($services.Count -eq 0) {
    throw "Service topology manifest did not declare any services."
}

$expected = [ordered]@{}
foreach ($service in $services) {
    $expected[[string]$service.name] = [int]$service.port
}

$failures = [System.Collections.ArrayList]::new()

$envMappings = @{
    "HERALD_BASE_URL" = "herald-service"
    "SESSION_ENGINE_BASE_URL" = "session-engine"
    "EIDON_BASE_URL" = "eidon-orchestrator"
}

foreach ($envKey in $envMappings.Keys) {
    $serviceName = $envMappings[$envKey]
    $expectedPort = $expected[$serviceName]
    $envValue = Get-EnvValue -Path $envExamplePath -Key $envKey

    if ($null -eq $envValue) {
        Add-Failure -Failures $failures -Message ".env.example missing $envKey"
        continue
    }

    if ($envValue -notmatch (":{0}$" -f $expectedPort)) {
        Add-Failure -Failures $failures -Message ".env.example $envKey does not match topology port $expectedPort for $serviceName"
    }
}

$testsReadme = Get-Content $testsReadmePath -Raw
foreach ($serviceName in $expected.Keys) {
    $expectedPort = $expected[$serviceName]
    if (-not (Test-DocumentContainsServicePort -Content $testsReadme -ServiceName $serviceName -Port $expectedPort)) {
        Add-Failure -Failures $failures -Message "tests/README.md does not reflect $serviceName port $expectedPort"
    }
}

$scriptsReadme = Get-Content $scriptsReadmePath -Raw
foreach ($serviceName in $expected.Keys) {
    $expectedPort = $expected[$serviceName]
    if (-not (Test-DocumentContainsServicePort -Content $scriptsReadme -ServiceName $serviceName -Port $expectedPort)) {
        Add-Failure -Failures $failures -Message "scripts/README.md does not reflect $serviceName port $expectedPort"
    }
}

$startScript = Get-Content $startScriptPath -Raw
if ($startScript -notmatch [regex]::Escape('config\service_topology_manifest.json')) {
    Add-Failure -Failures $failures -Message "scripts/start_phase_2_stack.ps1 is not loading config\service_topology_manifest.json"
}

foreach ($requiredToken in @('startup_workdir', 'startup_command', 'health_url')) {
    if ($startScript -notmatch [regex]::Escape($requiredToken)) {
        Add-Failure -Failures $failures -Message "scripts/start_phase_2_stack.ps1 is not using manifest field $requiredToken"
    }
}

$signalGatewayMain = Get-Content $signalGatewayMainPath -Raw
$heraldExpected = $expected["herald-service"]
$sessionExpected = $expected["session-engine"]

if ($signalGatewayMain -notmatch [regex]::Escape("HERALD_BASE_URL = os.getenv(`"HERALD_BASE_URL`", `"http://127.0.0.1:$heraldExpected`")")) {
    Add-Failure -Failures $failures -Message "services/signal-gateway/app/main.py does not reflect herald-service default port $heraldExpected"
}

if ($signalGatewayMain -notmatch [regex]::Escape("SESSION_ENGINE_BASE_URL = os.getenv(`"SESSION_ENGINE_BASE_URL`", `"http://127.0.0.1:$sessionExpected`")")) {
    Add-Failure -Failures $failures -Message "services/signal-gateway/app/main.py does not reflect session-engine default port $sessionExpected"
}

$fullChainTest = Get-Content $fullChainTestPath -Raw
if ($fullChainTest -notmatch [regex]::Escape("[string]`$SessionEngineBaseUrl = `"http://127.0.0.1:$sessionExpected`"")) {
    Add-Failure -Failures $failures -Message "tests/integration/test_full_chain.ps1 does not reflect session-engine default port $sessionExpected"
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    env_example_path = $envExamplePath
    tests_readme_path = $testsReadmePath
    start_script_path = $startScriptPath
    scripts_readme_path = $scriptsReadmePath
    signal_gateway_main_path = $signalGatewayMainPath
    full_chain_test_path = $fullChainTestPath
    expected_ports = $expected
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
