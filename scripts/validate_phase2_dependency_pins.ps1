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

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$truthPath = Join-Path $resolvedRepoRoot "config\phase2_python_dependency_truth.json"

if (-not (Test-Path $truthPath)) {
    throw "Missing Phase 2 dependency truth file at $truthPath"
}

$truth = Get-Content $truthPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()
$serviceResults = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$truth.manifest_version)) {
    Add-Failure -Failures $failures -Message "dependency truth file missing manifest_version"
}

$editableCommonSchemasLine = [string]$truth.editable_common_schemas_line
if ([string]::IsNullOrWhiteSpace($editableCommonSchemasLine)) {
    Add-Failure -Failures $failures -Message "dependency truth file missing editable_common_schemas_line"
}

$serviceRequirements = @($truth.service_requirements)
if ($serviceRequirements.Count -eq 0) {
    Add-Failure -Failures $failures -Message "dependency truth file has no service_requirements"
}

foreach ($entry in $serviceRequirements) {
    $serviceName = [string]$entry.service
    $relativePath = [string]$entry.path
    $requiredPins = @($entry.required_pins)
    $serviceFailures = [System.Collections.ArrayList]::new()

    if ([string]::IsNullOrWhiteSpace($serviceName)) {
        Add-Failure -Failures $serviceFailures -Message "missing service name"
    }

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        Add-Failure -Failures $serviceFailures -Message "missing requirements path"
    }

    if ($requiredPins.Count -eq 0) {
        Add-Failure -Failures $serviceFailures -Message "missing required pins"
    }

    $requirementsPath = Join-Path $resolvedRepoRoot $relativePath

    if (-not (Test-Path $requirementsPath)) {
        Add-Failure -Failures $serviceFailures -Message "requirements.txt missing"
    }
    else {
        $lines = Get-Content $requirementsPath | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $nonCommentLines = @($lines | Where-Object { -not $_.StartsWith("#") })

        $editableLines = @($nonCommentLines | Where-Object { $_ -eq $editableCommonSchemasLine })
        if ($editableLines.Count -ne 1) {
            Add-Failure -Failures $serviceFailures -Message ("expected exactly one editable common-schemas line '{0}'" -f $editableCommonSchemasLine)
        }

        foreach ($requiredPin in $requiredPins) {
            if ($requiredPin -notin $nonCommentLines) {
                Add-Failure -Failures $serviceFailures -Message ("missing required pin '{0}'" -f $requiredPin)
            }
        }

        foreach ($line in $nonCommentLines) {
            if ($line -eq $editableCommonSchemasLine) {
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
        $prefix = if ([string]::IsNullOrWhiteSpace($serviceName)) { "<unnamed-service>" } else { $serviceName }
        Add-Failure -Failures $failures -Message ("{0}: {1}" -f $prefix, $failure)
    }
}

$sharedPackageFailures = [System.Collections.ArrayList]::new()
$sharedPackage = $truth.shared_package

if ($null -eq $sharedPackage) {
    Add-Failure -Failures $sharedPackageFailures -Message "missing shared_package section"
}
else {
    $sharedRelativePath = [string]$sharedPackage.path
    $sharedProjectName = [string]$sharedPackage.project_name
    $sharedRequiredPins = @($sharedPackage.required_dependency_pins)

    if ([string]::IsNullOrWhiteSpace($sharedRelativePath)) {
        Add-Failure -Failures $sharedPackageFailures -Message "shared package missing path"
    }

    if ([string]::IsNullOrWhiteSpace($sharedProjectName)) {
        Add-Failure -Failures $sharedPackageFailures -Message "shared package missing project_name"
    }

    if ($sharedRequiredPins.Count -eq 0) {
        Add-Failure -Failures $sharedPackageFailures -Message "shared package missing required_dependency_pins"
    }

    $pyprojectPath = Join-Path $resolvedRepoRoot $sharedRelativePath

    if (-not (Test-Path $pyprojectPath)) {
        Add-Failure -Failures $sharedPackageFailures -Message "pyproject.toml missing"
    }
    else {
        $pyprojectText = Get-Content $pyprojectPath -Raw

        if ($pyprojectText -notmatch ("name\s*=\s*`"{0}`"" -f [regex]::Escape($sharedProjectName))) {
            Add-Failure -Failures $sharedPackageFailures -Message ("project name '{0}' missing" -f $sharedProjectName)
        }

        foreach ($requiredPin in $sharedRequiredPins) {
            $escapedPin = [regex]::Escape($requiredPin)
            if ($pyprojectText -notmatch $escapedPin) {
                Add-Failure -Failures $sharedPackageFailures -Message ("shared package dependency pin '{0}' missing" -f $requiredPin)
            }
        }
    }
}

foreach ($failure in $sharedPackageFailures) {
    Add-Failure -Failures $failures -Message ("eidonic-schemas: {0}" -f $failure)
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    repo_root = $resolvedRepoRoot
    dependency_truth_path = $truthPath
    manifest_version = [string]$truth.manifest_version
    service_results = $serviceResults
    shared_package = [ordered]@{
        path = if ($null -ne $sharedPackage) { (Join-Path $resolvedRepoRoot ([string]$sharedPackage.path)) } else { $null }
        status = $(if ($sharedPackageFailures.Count -eq 0) { "passed" } else { "failed" })
        failures = @($sharedPackageFailures)
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
