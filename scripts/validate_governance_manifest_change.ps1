param(
    [string]$CurrentManifestPath = ".\config\governance_rules_manifest.json",
    [string]$BaselineManifestPath = ".\config\baselines\governance_rules_manifest_baseline.json",
    [string]$ChangeRecordsDirectory = ".\docs\decision_records",
    [string]$ChangeRecordPattern = "GOVERNANCE_MANIFEST_CHANGE_RECORD_*.md"
)

$ErrorActionPreference = "Stop"

function Normalize-JsonObject {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    return ($InputObject | ConvertTo-Json -Depth 100)
}

function Get-RuleMap {
    param(
        [object[]]$Rules
    )

    $map = @{}

    foreach ($rule in $Rules) {
        if ($null -eq $rule) {
            continue
        }

        $ruleId = [string]$rule.rule_id
        if ([string]::IsNullOrWhiteSpace($ruleId)) {
            continue
        }

        $map[$ruleId] = ($rule | ConvertTo-Json -Depth 100)
    }

    return $map
}

$currentManifestFullPath = Resolve-Path $CurrentManifestPath
$baselineManifestFullPath = Resolve-Path $BaselineManifestPath
$changeRecordsFullPath = Resolve-Path $ChangeRecordsDirectory

$current = Get-Content $currentManifestFullPath -Raw | ConvertFrom-Json
$baseline = Get-Content $baselineManifestFullPath -Raw | ConvertFrom-Json

$currentNormalized = Normalize-JsonObject -InputObject $current
$baselineNormalized = Normalize-JsonObject -InputObject $baseline

$manifestChanged = $currentNormalized -ne $baselineNormalized

$currentVersion = [string]$current.manifest_version
$baselineVersion = [string]$baseline.manifest_version
$versionChanged = $currentVersion -ne $baselineVersion

$currentRules = @()
if ($null -ne $current.rules) {
    $currentRules = @($current.rules)
}

$baselineRules = @()
if ($null -ne $baseline.rules) {
    $baselineRules = @($baseline.rules)
}

$currentRuleMap = Get-RuleMap -Rules $currentRules
$baselineRuleMap = Get-RuleMap -Rules $baselineRules

$currentRuleIds = @($currentRuleMap.Keys | Sort-Object)
$baselineRuleIds = @($baselineRuleMap.Keys | Sort-Object)

$addedRuleIds = @($currentRuleIds | Where-Object { $_ -notin $baselineRuleIds })
$removedRuleIds = @($baselineRuleIds | Where-Object { $_ -notin $currentRuleIds })

$changedRuleIds = @()
foreach ($ruleId in ($currentRuleIds | Where-Object { $_ -in $baselineRuleIds })) {
    if ($currentRuleMap[$ruleId] -ne $baselineRuleMap[$ruleId]) {
        $changedRuleIds += $ruleId
    }
}

$recordFiles = @(Get-ChildItem -Path $changeRecordsFullPath -Filter $ChangeRecordPattern -File | Sort-Object Name)
$recordMentionsCurrentVersion = @()

if (-not [string]::IsNullOrWhiteSpace($currentVersion)) {
    foreach ($file in $recordFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match [regex]::Escape($currentVersion)) {
            $recordMentionsCurrentVersion += $file.Name
        }
    }
}

$hasMatchingChangeRecord = $recordMentionsCurrentVersion.Count -gt 0

$status = "passed"
$failureReasons = @()

if ($manifestChanged) {
    if (-not $versionChanged) {
        $status = "failed"
        $failureReasons += "manifest_changed_without_version_change"
    }

    if (-not $hasMatchingChangeRecord) {
        $status = "failed"
        $failureReasons += "manifest_changed_without_matching_change_record"
    }
}

$summary = [ordered]@{
    status = $status
    manifest_changed = $manifestChanged
    current_manifest_version = $currentVersion
    baseline_manifest_version = $baselineVersion
    version_changed = $versionChanged
    current_rule_count = $currentRuleIds.Count
    baseline_rule_count = $baselineRuleIds.Count
    added_rule_ids = $addedRuleIds
    removed_rule_ids = $removedRuleIds
    changed_rule_ids = $changedRuleIds
    change_record_count = $recordFiles.Count
    matching_change_record_count = $recordMentionsCurrentVersion.Count
    matching_change_records = $recordMentionsCurrentVersion
    failure_reasons = $failureReasons
}

Write-Host ""
Write-Host "Validating governance manifest change discipline..." -ForegroundColor Yellow
Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 12)

if ($summary.status -ne "passed") {
    throw "Governance manifest change validation failed."
}

Write-Host ""
Write-Host "Governance manifest change validation passed." -ForegroundColor Green
