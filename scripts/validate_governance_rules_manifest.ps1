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
$manifestPath = Join-Path $resolvedRepoRoot "config\governance_rules_manifest.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing governance rules manifest at $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$failures = [System.Collections.ArrayList]::new()

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    Add-Failure -Failures $failures -Message "missing manifest_version"
}

$allowedOutcomes = @("allow", "fallback", "refuse", "hold", "reshape", "handoff")
$allowedMatchModes = @("contains_any", "contains_all")

if ($null -eq $manifest.default_success) {
    Add-Failure -Failures $failures -Message "missing default_success"
}
else {
    if ([string]::IsNullOrWhiteSpace([string]$manifest.default_success.governance_outcome)) {
        Add-Failure -Failures $failures -Message "default_success missing governance_outcome"
    }
    elseif ($manifest.default_success.governance_outcome -notin $allowedOutcomes) {
        Add-Failure -Failures $failures -Message ("default_success governance_outcome '{0}' is invalid" -f $manifest.default_success.governance_outcome)
    }

    if ([string]::IsNullOrWhiteSpace([string]$manifest.default_success.governance_reason)) {
        Add-Failure -Failures $failures -Message "default_success missing governance_reason"
    }

    if ([string]::IsNullOrWhiteSpace([string]$manifest.default_success.rule_id)) {
        Add-Failure -Failures $failures -Message "default_success missing rule_id"
    }
}

$rules = @($manifest.rules)
if ($rules.Count -eq 0) {
    Add-Failure -Failures $failures -Message "manifest has no rules"
}

$ruleIds = @{}
$results = [System.Collections.ArrayList]::new()

foreach ($rule in $rules) {
    $ruleFailures = [System.Collections.ArrayList]::new()
    $ruleId = [string]$rule.rule_id
    $enabled = $rule.enabled
    $matchMode = [string]$rule.match_mode
    $signalTypes = @($rule.signal_types)
    $patterns = @($rule.patterns)
    $outcome = [string]$rule.governance_outcome
    $reason = [string]$rule.governance_reason
    $responseText = [string]$rule.response_text

    if ([string]::IsNullOrWhiteSpace($ruleId)) {
        Add-Failure -Failures $ruleFailures -Message "missing rule_id"
    }
    elseif ($ruleIds.ContainsKey($ruleId)) {
        Add-Failure -Failures $ruleFailures -Message ("duplicate rule_id '{0}'" -f $ruleId)
    }
    else {
        $ruleIds[$ruleId] = $true
    }

    if ($null -eq $enabled) {
        Add-Failure -Failures $ruleFailures -Message "missing enabled"
    }

    if ([string]::IsNullOrWhiteSpace($matchMode)) {
        Add-Failure -Failures $ruleFailures -Message "missing match_mode"
    }
    elseif ($matchMode -notin $allowedMatchModes) {
        Add-Failure -Failures $ruleFailures -Message ("invalid match_mode '{0}'" -f $matchMode)
    }

    if ($signalTypes.Count -eq 0) {
        Add-Failure -Failures $ruleFailures -Message "missing signal_types"
    }
    else {
        $usableSignalTypes = @($signalTypes | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        if ($usableSignalTypes.Count -eq 0) {
            Add-Failure -Failures $ruleFailures -Message "signal_types contains no usable values"
        }
    }

    if ($patterns.Count -eq 0) {
        Add-Failure -Failures $ruleFailures -Message "missing patterns"
    }
    else {
        $usablePatterns = @($patterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        if ($usablePatterns.Count -eq 0) {
            Add-Failure -Failures $ruleFailures -Message "patterns contains no usable values"
        }
    }

    if ([string]::IsNullOrWhiteSpace($outcome)) {
        Add-Failure -Failures $ruleFailures -Message "missing governance_outcome"
    }
    elseif ($outcome -notin $allowedOutcomes) {
        Add-Failure -Failures $ruleFailures -Message ("invalid governance_outcome '{0}'" -f $outcome)
    }

    if ([string]::IsNullOrWhiteSpace($reason)) {
        Add-Failure -Failures $ruleFailures -Message "missing governance_reason"
    }

    if ([string]::IsNullOrWhiteSpace($responseText)) {
        Add-Failure -Failures $ruleFailures -Message "missing response_text"
    }

    $status = if ($ruleFailures.Count -eq 0) { "passed" } else { "failed" }

    [void]$results.Add([pscustomobject]@{
        rule_id = $ruleId
        status = $status
        failures = @($ruleFailures)
    })

    foreach ($failure in $ruleFailures) {
        Add-Failure -Failures $failures -Message ("{0}: {1}" -f $ruleId, $failure)
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_path = $manifestPath
    manifest_version = [string]$manifest.manifest_version
    total_rules = $rules.Count
    failed_rules = @($results | Where-Object { $_.status -eq "failed" }).Count
    allowed_outcomes = $allowedOutcomes
    allowed_match_modes = $allowedMatchModes
    results = $results
    failures = @($failures)
}

Write-Host ""
Write-Host "Governance rules manifest validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne "passed") {
    throw "Governance rules manifest validation failed."
}

Write-Host ""
Write-Host "Governance rules manifest validation passed." -ForegroundColor Green
