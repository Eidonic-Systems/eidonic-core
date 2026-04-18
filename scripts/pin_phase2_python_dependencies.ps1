param(
    [string]$RepoRoot = ".",
    [string[]]$Services = @(
        "eidon-orchestrator",
        "signal-gateway",
        "session-engine",
        "herald-service"
    )
)

$ErrorActionPreference = "Stop"

function Get-InstalledVersion {
    param(
        [string]$PythonExe,
        [string]$PackageName
    )

    $raw = & $PythonExe -m pip show $PackageName 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($raw | Out-String))) {
        return $null
    }

    foreach ($line in $raw) {
        if ($line -match '^Version:\s*(.+)$') {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Should-SkipLine {
    param([string]$Trimmed)

    if ([string]::IsNullOrWhiteSpace($Trimmed)) { return $true }
    if ($Trimmed.StartsWith("#")) { return $true }
    if ($Trimmed.StartsWith("-e ")) { return $true }
    if ($Trimmed.StartsWith("--")) { return $true }
    if ($Trimmed.StartsWith("git+")) { return $true }
    if ($Trimmed.StartsWith("http://")) { return $true }
    if ($Trimmed.StartsWith("https://")) { return $true }
    if ($Trimmed.StartsWith(".")) { return $true }
    if ($Trimmed.StartsWith("/")) { return $true }
    if ($Trimmed.StartsWith("..")) { return $true }
    if ($Trimmed -match '[\\/]' -and $Trimmed -notmatch '^[A-Za-z0-9_.-]+(\[[A-Za-z0-9_,.-]+\])?(==.+)?$') { return $true }
    return $false
}

function Get-RequirementIdentity {
    param([string]$Trimmed)

    if ($Trimmed -match '^(?<name>[A-Za-z0-9_.-]+)(?<extras>\[[A-Za-z0-9_,.-]+\])?$') {
        return [pscustomobject]@{
            package = $Matches['name']
            rendered = $Trimmed
        }
    }

    if ($Trimmed -match '^(?<name>[A-Za-z0-9_.-]+)(?<extras>\[[A-Za-z0-9_,.-]+\])?(?<op>>=|<=|~=|!=|>|<).+$') {
        return [pscustomobject]@{
            package = $Matches['name']
            rendered = $null
        }
    }

    return $null
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$summary = [System.Collections.ArrayList]::new()

foreach ($service in $Services) {
    $serviceRoot = Join-Path $resolvedRepoRoot ("services\{0}" -f $service)
    $requirementsPath = Join-Path $serviceRoot "requirements.txt"
    $pythonExe = Join-Path $serviceRoot ".venv\Scripts\python.exe"

    if (-not (Test-Path $requirementsPath)) {
        [void]$summary.Add([pscustomobject]@{
            service = $service
            status = "skipped"
            detail = "requirements.txt not found"
            pinned = @()
            unresolved = @()
        })
        continue
    }

    if (-not (Test-Path $pythonExe)) {
        throw "Missing service venv python for $service at $pythonExe"
    }

    $lines = Get-Content $requirementsPath
    $newLines = [System.Collections.Generic.List[string]]::new()
    $pinned = [System.Collections.ArrayList]::new()
    $unresolved = [System.Collections.ArrayList]::new()

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if (Should-SkipLine -Trimmed $trimmed) {
            $newLines.Add($line)
            continue
        }

        if ($trimmed -match '==') {
            $newLines.Add($line)
            continue
        }

        $identity = Get-RequirementIdentity -Trimmed $trimmed
        if ($null -eq $identity) {
            $newLines.Add($line)
            [void]$unresolved.Add($trimmed)
            continue
        }

        if ($null -eq $identity.rendered) {
            $newLines.Add($line)
            [void]$unresolved.Add($trimmed)
            continue
        }

        $version = Get-InstalledVersion -PythonExe $pythonExe -PackageName $identity.package
        if ([string]::IsNullOrWhiteSpace($version)) {
            $newLines.Add($line)
            [void]$unresolved.Add($trimmed)
            continue
        }

        $rendered = "{0}=={1}" -f $identity.rendered, $version
        $newLines.Add($rendered)
        [void]$pinned.Add([pscustomobject]@{
            original = $trimmed
            pinned = $rendered
        })
    }

    Set-Content -Path $requirementsPath -Value $newLines

    [void]$summary.Add([pscustomobject]@{
        service = $service
        status = "processed"
        detail = $requirementsPath
        pinned = @($pinned)
        unresolved = @($unresolved)
    })
}

$allUnresolved = @($summary | ForEach-Object { $_.unresolved } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

$result = [ordered]@{
    status = $(if ($allUnresolved.Count -eq 0) { "passed" } else { "warning" })
    repo_root = $resolvedRepoRoot
    services = $summary
    unresolved = $allUnresolved
}

Write-Host ""
Write-Host "Phase 2 dependency reproducibility summary:" -ForegroundColor Yellow
Write-Host ($result | ConvertTo-Json -Depth 10)

Write-Host ""
if ($result.status -eq "passed") {
    Write-Host "Phase 2 dependency reproducibility pinning passed." -ForegroundColor Green
}
else {
    Write-Host "Phase 2 dependency reproducibility pinning completed with unresolved entries." -ForegroundColor Yellow
}
