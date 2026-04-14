param(
    [string]$CurrentPath = ".\config\governance_rules_manifest.json",
    [string]$BaselinePath = ".\config\baselines\governance_rules_manifest_baseline.json"
)

$ErrorActionPreference = "Stop"

function Normalize-JsonObject {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    return ($InputObject | ConvertTo-Json -Depth 100)
}

$currentFullPath = Resolve-Path $CurrentPath
$baselineFullPath = Resolve-Path $BaselinePath

$current = Get-Content $currentFullPath -Raw | ConvertFrom-Json
$baseline = Get-Content $baselineFullPath -Raw | ConvertFrom-Json

$currentNormalized = Normalize-JsonObject -InputObject $current
$baselineNormalized = Normalize-JsonObject -InputObject $baseline

$currentRuleIds = @()
if ($null -ne $current.rules) {
    $currentRuleIds = @($current.rules | ForEach-Object { [string]$_.rule_id })
}

$baselineRuleIds = @()
if ($null -ne $baseline.rules) {
    $baselineRuleIds = @($baseline.rules | ForEach-Object { [string]$_.rule_id })
}

$addedRuleIds = @($currentRuleIds | Where-Object { $_ -notin $baselineRuleIds })
$removedRuleIds = @($baselineRuleIds | Where-Object { $_ -notin $currentRuleIds })

$summary = [ordered]@{
    status = if ($currentNormalized -eq $baselineNormalized) { "passed" } else { "failed" }
    current_manifest_version = [string]$current.manifest_version
    baseline_manifest_version = [string]$baseline.manifest_version
    current_rule_count = $currentRuleIds.Count
    baseline_rule_count = $baselineRuleIds.Count
    added_rule_ids = $addedRuleIds
    removed_rule_ids = $removedRuleIds
    manifest_changed = ($currentNormalized -ne $baselineNormalized)
}

Write-Host ""
Write-Host "Comparing governance manifest to baseline..." -ForegroundColor Yellow
Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 12)

if ($summary.status -ne "passed") {
    throw "Governance manifest baseline comparison failed."
}

Write-Host ""
Write-Host "Governance manifest baseline comparison passed." -ForegroundColor Green
