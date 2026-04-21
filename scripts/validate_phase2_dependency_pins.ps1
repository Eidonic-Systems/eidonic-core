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

function Test-ExactPinLine {
    param(
        [string]$Line
    )

    return ($Line -match '^[A-Za-z0-9_.-]+(\[[A-Za-z0-9_,.-]+\])?==[^=\s]+$')
}

function Test-EditableLocalPathLine {
    param(
        [string]$Line
    )

    return ($Line -match '^-e\s+\.\.\/\.\.\/packages\/common-schemas\/python$' -or
            $Line -match '^-e\s+\.\.\\\.\.\\packages\\common-schemas\\python$')
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path

$serviceRequirements = @(
    @{
        Service = "signal-gateway"
        Path = Join-Path $resolvedRepoRoot "services\signal-gateway\requirements.txt"
        RequiredPins = @(
            "fastapi==0.136.0",
            "uvicorn==0.44.0",
            "pydantic==2.13.3",
            "httpx==0.28.1",
            "python-dotenv==1.2.2",
            "psycopg[binary]==3.3.3"
        )
    },
    @{
        Service = "herald-service"
        Path = Join-Path $resolvedRepoRoot "services\herald-service\requirements.txt"
        RequiredPins = @(
            "fastapi==0.136.0",
            "uvicorn==0.44.0",
            "pydantic==2.13.3",
            "python-dotenv==1.2.2",
            "psycopg[binary]==3.3.3"
        )
    },
    @{
        Service = "session-engine"
        Path = Join-Path $resolvedRepoRoot "services\session-engine\requirements.txt"
        RequiredPins = @(
            "fastapi==0.136.0",
            "uvicorn==0.44.0",
            "pydantic==2.13.3",
            "python-dotenv==1.2.2",
            "psycopg[binary]==3.3.3"
        )
    },
    @{
        Service = "eidon-orchestrator"
        Path = Join-Path $resolvedRepoRoot "services\eidon-orchestrator\requirements.txt"
        RequiredPins = @(
            "fastapi==0.136.0",
            "uvicorn==0.44.0",
            "pydantic==2.13.3",
            "httpx==0.28.1",
            "python-dotenv==1.2.2",
            "psycopg[binary]==3.3.3"
        )
    }
)

$pyprojectPath = Join-Path $resolvedRepoRoot "packages\common-schemas\python\pyproject.toml"

$failures = [System.Collections.ArrayList]::new()
$serviceResults = [System.Collections.ArrayList]::new()

foreach ($entry in $serviceRequirements) {
    $serviceName = $entry.Service
    $requirementsPath = $entry.Path
    $requiredPins = @($entry.RequiredPins)
    $serviceFailures = [System.Collections.ArrayList]::new()

    if (-not (Test-Path $requirementsPath)) {
        Add-Failure -Failures $serviceFailures -Message "requirements.txt missing"
    }
    else {
        $lines = Get-Content $requirementsPath | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $nonCommentLines = @($lines | Where-Object { -not $_.StartsWith("#") })

        $editableLines = @($nonCommentLines | Where-Object { Test-EditableLocalPathLine -Line $_ })
        if ($editableLines.Count -ne 1) {
            Add-Failure -Failures $serviceFailures -Message "expected exactly one editable common-schemas line"
        }

        foreach ($requiredPin in $requiredPins) {
            if ($requiredPin -notin $nonCommentLines) {
                Add-Failure -Failures $serviceFailures -Message ("missing required pin '{0}'" -f $requiredPin)
            }
        }

        foreach ($line in $nonCommentLines) {
            if (Test-EditableLocalPathLine -Line $line) {
                continue
            }

            if (-not (Test-ExactPinLine -Line $line)) {
                Add-Failure -Failures $serviceFailures -Message ("non-exact or unsupported requirement line '{0}'" -f $line)
            }
        }
    }

    $status = if ($serviceFailures.Count -eq 0) { "passed" } else { "failed" }

    [void]$serviceResults.Add([pscustomobject]@{
        service = $serviceName
        requirements_path = $requirementsPath
        status = $status
        failures = @($serviceFailures)
    })

    foreach ($failure in $serviceFailures) {
        Add-Failure -Failures $failures -Message ("{0}: {1}" -f $serviceName, $failure)
    }
}

$pyprojectFailures = [System.Collections.ArrayList]::new()

if (-not (Test-Path $pyprojectPath)) {
    Add-Failure -Failures $pyprojectFailures -Message "pyproject.toml missing"
}
else {
    $pyprojectText = Get-Content $pyprojectPath -Raw
    if ($pyprojectText -notmatch 'name\s*=\s*"eidonic-schemas"') {
        Add-Failure -Failures $pyprojectFailures -Message 'project name "eidonic-schemas" missing'
    }

    if ($pyprojectText -notmatch 'pydantic==2\.13\.3') {
        Add-Failure -Failures $pyprojectFailures -Message 'shared package pydantic pin "2.13.3" missing'
    }
}

foreach ($failure in $pyprojectFailures) {
    Add-Failure -Failures $failures -Message ("eidonic-schemas: {0}" -f $failure)
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    repo_root = $resolvedRepoRoot
    service_results = $serviceResults
    shared_package = [ordered]@{
        path = $pyprojectPath
        status = $(if ($pyprojectFailures.Count -eq 0) { "passed" } else { "failed" })
        failures = @($pyprojectFailures)
    }
    failures = @($failures)
}

Write-Host ""
Write-Host "Phase 2 dependency pin validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne "passed") {
    throw "Phase 2 dependency pin validation failed."
}

Write-Host ""
Write-Host "Phase 2 dependency pin validation passed." -ForegroundColor Green


