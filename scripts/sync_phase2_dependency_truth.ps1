param(
    [string]$RepoRoot = ".",
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

function Normalize-Text {
    param(
        [string]$Text
    )

    if ($null -eq $Text) {
        return ""
    }

    return ($Text -replace "`r?`n", "`r`n")
}

function Get-NormalizedRequirementLines {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    return @(
        $Text -split "(`r`n|`n|`r)" |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() }
    )
}

function Test-RequirementContentAligned {
    param(
        [string]$CurrentText,
        [string]$TargetText
    )

    $currentLines = @(Get-NormalizedRequirementLines -Text $CurrentText | Sort-Object)
    $targetLines = @(Get-NormalizedRequirementLines -Text $TargetText | Sort-Object)

    if ($currentLines.Count -ne $targetLines.Count) {
        return $false
    }

    for ($i = 0; $i -lt $currentLines.Count; $i++) {
        if ($currentLines[$i] -ne $targetLines[$i]) {
            return $false
        }
    }

    return $true
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$truthPath = Join-Path $resolvedRepoRoot "config\phase2_python_dependency_truth.json"

if (-not (Test-Path $truthPath)) {
    throw "Missing Phase 2 dependency truth file at $truthPath"
}

$truth = Get-Content $truthPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace([string]$truth.manifest_version)) {
    throw "Dependency truth file missing manifest_version."
}

$editableCommonSchemasLine = [string]$truth.editable_common_schemas_line
if ([string]::IsNullOrWhiteSpace($editableCommonSchemasLine)) {
    throw "Dependency truth file missing editable_common_schemas_line."
}

$serviceRequirements = @($truth.service_requirements)
if ($serviceRequirements.Count -eq 0) {
    throw "Dependency truth file has no service_requirements."
}

Write-Section -Label "Syncing Phase 2 service requirements from dependency truth"

foreach ($entry in $serviceRequirements) {
    $serviceName = [string]$entry.service
    $relativePath = [string]$entry.path
    $requiredPins = @($entry.required_pins)

    if ([string]::IsNullOrWhiteSpace($serviceName)) {
        throw "Service requirement entry missing service name."
    }

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        throw "Service requirement entry missing path for service '$serviceName'."
    }

    if ($requiredPins.Count -eq 0) {
        throw "Service requirement entry missing required pins for service '$serviceName'."
    }

    $targetPath = Join-Path $resolvedRepoRoot $relativePath
    if (-not (Test-Path $targetPath)) {
        throw "Missing requirements target for service '$serviceName' at $targetPath"
    }

    $targetLines = @($editableCommonSchemasLine) + $requiredPins
    $targetContent = ($targetLines -join "`r`n") + "`r`n"
    $currentContent = Get-Content $targetPath -Raw
    $isAligned = Test-RequirementContentAligned -CurrentText $currentContent -TargetText $targetContent

    if ($DryRun) {
        if ($isAligned) {
            Write-Host ("[DRY-RUN] {0} already aligned -> {1}" -f $serviceName, $targetPath) -ForegroundColor Cyan
        }
        else {
            Write-Host ("[DRY-RUN] would sync {0} -> {1}" -f $serviceName, $targetPath) -ForegroundColor Cyan
            Write-Host $targetContent
        }
    }
    else {
        if ($isAligned) {
            Write-Host ("Already aligned {0} -> {1}" -f $serviceName, $targetPath) -ForegroundColor Green
        }
        else {
            Set-Content -Path $targetPath -Value $targetContent -NoNewline
            Write-Host ("Synced {0} -> {1}" -f $serviceName, $targetPath) -ForegroundColor Green
        }
    }
}

$sharedPackage = $truth.shared_package
if ($null -eq $sharedPackage) {
    throw "Dependency truth file missing shared_package section."
}

$sharedRelativePath = [string]$sharedPackage.path
$sharedRequiredPins = @($sharedPackage.required_dependency_pins)

if ([string]::IsNullOrWhiteSpace($sharedRelativePath)) {
    throw "Dependency truth file shared_package missing path."
}

if ($sharedRequiredPins.Count -eq 0) {
    throw "Dependency truth file shared_package missing required_dependency_pins."
}

$pyprojectPath = Join-Path $resolvedRepoRoot $sharedRelativePath
if (-not (Test-Path $pyprojectPath)) {
    throw "Missing shared package pyproject at $pyprojectPath"
}

Write-Section -Label "Syncing shared package dependencies from dependency truth"

$pyprojectText = Get-Content $pyprojectPath -Raw

if ($pyprojectText -notmatch '(?ms)^dependencies\s*=\s*\[.*?\]') {
    throw "Could not find dependencies block in $pyprojectPath"
}

$dependencyBlockLines = @("dependencies = [")
foreach ($pin in $sharedRequiredPins) {
    $dependencyBlockLines += ('  "{0}"' -f $pin)
}
$dependencyBlockLines += "]"

$dependencyBlock = $dependencyBlockLines -join "`r`n"

$updatedPyprojectText = [regex]::Replace(
    $pyprojectText,
    '(?ms)^dependencies\s*=\s*\[.*?\]',
    $dependencyBlock,
    1
)

$isSharedAligned = (Normalize-Text $pyprojectText) -eq (Normalize-Text $updatedPyprojectText)

if ($DryRun) {
    if ($isSharedAligned) {
        Write-Host ("[DRY-RUN] shared package already aligned -> {0}" -f $pyprojectPath) -ForegroundColor Cyan
    }
    else {
        Write-Host ("[DRY-RUN] would sync shared package -> {0}" -f $pyprojectPath) -ForegroundColor Cyan
        Write-Host $dependencyBlock
    }
}
else {
    if ($isSharedAligned) {
        Write-Host ("Already aligned shared package -> {0}" -f $pyprojectPath) -ForegroundColor Green
    }
    else {
        Set-Content -Path $pyprojectPath -Value $updatedPyprojectText -NoNewline
        Write-Host ("Synced shared package -> {0}" -f $pyprojectPath) -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Phase 2 dependency truth sync completed." -ForegroundColor Green
