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

function Test-PathArray {
    param(
        [string[]]$Paths,
        [string]$Label,
        [string]$RepoRootPath,
        [System.Collections.ArrayList]$Failures,
        [System.Collections.ArrayList]$PathsSeen
    )

    if (@($Paths).Count -eq 0) {
        Add-Failure -Failures $Failures -Message ("automation helper surface manifest has no {0}" -f $Label)
        return
    }

    foreach ($relativePath in @($Paths)) {
        $pathText = [string]$relativePath

        if ([string]::IsNullOrWhiteSpace($pathText)) {
            Add-Failure -Failures $Failures -Message ("{0} contains a blank path entry" -f $Label)
            continue
        }

        if ($pathText -in $PathsSeen) {
            Add-Failure -Failures $Failures -Message ("duplicate automation helper surface path '{0}'" -f $pathText)
        }
        else {
            [void]$PathsSeen.Add($pathText)
        }

        if ($Label -eq 'helper_scripts' -and $pathText -notmatch '^scripts[\\/].+\.ps1$') {
            Add-Failure -Failures $Failures -Message ("helper_scripts entry must point to a PowerShell script under scripts/: '{0}'" -f $pathText)
        }

        if ([System.IO.Path]::IsPathRooted($pathText)) {
            Add-Failure -Failures $Failures -Message ("automation helper surface entries must be repo-relative, not rooted: '{0}'" -f $pathText)
        }

        $resolvedPath = Join-Path $RepoRootPath $pathText
        if (-not (Test-Path $resolvedPath)) {
            Add-Failure -Failures $Failures -Message ("automation helper surface path missing on disk: '{0}'" -f $pathText)
        }
    }
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\automation_helper_surface_manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing automation helper surface manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    Add-Failure -Failures $failures -Message "automation helper surface manifest missing manifest_version"
}

foreach ($requiredProperty in @('helper_scripts', 'supporting_surfaces')) {
    if (-not ($manifest.PSObject.Properties.Name -contains $requiredProperty)) {
        Add-Failure -Failures $failures -Message ("automation helper surface manifest missing {0}" -f $requiredProperty)
    }
}

$pathsSeen = [System.Collections.ArrayList]::new()

Test-PathArray -Paths @($manifest.helper_scripts) -Label 'helper_scripts' -RepoRootPath $resolvedRepoRoot -Failures $failures -PathsSeen $pathsSeen
Test-PathArray -Paths @($manifest.supporting_surfaces) -Label 'supporting_surfaces' -RepoRootPath $resolvedRepoRoot -Failures $failures -PathsSeen $pathsSeen

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    helper_script_count = @($manifest.helper_scripts).Count
    supporting_surface_count = @($manifest.supporting_surfaces).Count
    failures = @($failures)
}

Write-Host ""
Write-Host "Automation helper surface manifest validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Automation helper surface manifest validation failed."
}

Write-Host ""
Write-Host "Automation helper surface manifest validation passed." -ForegroundColor Green
