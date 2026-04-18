param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$manifestPath = Join-Path $resolvedRepoRoot "config\governance_rules_manifest.json"
$fixturePath = Join-Path $resolvedRepoRoot "tests\fixtures\governance_rule_fixtures.json"

if (-not (Test-Path $manifestPath)) {
    throw "Missing governance rules manifest at $manifestPath"
}

if (-not (Test-Path $fixturePath)) {
    throw "Missing governance fixture file at $fixturePath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$fixtureSet = Get-Content $fixturePath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace([string]$manifest.manifest_version)) {
    throw "Governance manifest is missing manifest_version."
}

if ([string]::IsNullOrWhiteSpace([string]$fixtureSet.manifest_version)) {
    throw "Governance fixture file is missing manifest_version."
}

if ([string]$manifest.manifest_version -ne [string]$fixtureSet.manifest_version) {
    throw "Fixture manifest_version does not match governance manifest_version."
}

function Test-RuleMatch {
    param(
        $Rule,
        [string]$SignalType,
        [string]$Text
    )

    if (-not $Rule.enabled) {
        return $false
    }

    $signalTypes = @($Rule.signal_types | ForEach-Object { [string]$_ })
    if ($SignalType -notin $signalTypes) {
        return $false
    }

    $patterns = @($Rule.patterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { ([string]$_).ToLowerInvariant() })
    $textLower = ([string]$Text).ToLowerInvariant()

    if ($Rule.match_mode -eq "contains_any") {
        foreach ($pattern in $patterns) {
            if ($textLower.Contains($pattern)) {
                return $true
            }
        }
        return $false
    }

    if ($Rule.match_mode -eq "contains_all") {
        foreach ($pattern in $patterns) {
            if (-not $textLower.Contains($pattern)) {
                return $false
            }
        }
        return $true
    }

    throw "Unsupported match_mode '$($Rule.match_mode)' on rule '$($Rule.rule_id)'."
}

function Find-FirstMatch {
    param(
        $Manifest,
        [string]$SignalType,
        [string]$Text
    )

    foreach ($rule in $Manifest.rules) {
        if (Test-RuleMatch -Rule $rule -SignalType $SignalType -Text $Text) {
            return $rule
        }
    }

    return $null
}

$results = [System.Collections.ArrayList]::new()
$failures = [System.Collections.ArrayList]::new()

foreach ($fixture in $fixtureSet.fixtures) {
    $fixtureId = [string]$fixture.fixture_id
    $signalType = [string]$fixture.signal_type
    $text = [string]$fixture.text
    $shouldMatch = [bool]$fixture.should_match
    $expectedRuleId = [string]$fixture.expected_rule_id
    $expectedOutcome = [string]$fixture.expected_governance_outcome

    $matchedRule = Find-FirstMatch -Manifest $manifest -SignalType $signalType -Text $text
    $status = "passed"
    $failureReasons = [System.Collections.ArrayList]::new()

    if ($shouldMatch) {
        if ($null -eq $matchedRule) {
            $status = "failed"
            [void]$failureReasons.Add("expected a matching rule but found none")
        }
        else {
            if ([string]$matchedRule.rule_id -ne $expectedRuleId) {
                $status = "failed"
                [void]$failureReasons.Add(("expected rule_id '{0}' but got '{1}'" -f $expectedRuleId, [string]$matchedRule.rule_id))
            }

            if ([string]$matchedRule.governance_outcome -ne $expectedOutcome) {
                $status = "failed"
                [void]$failureReasons.Add(("expected governance_outcome '{0}' but got '{1}'" -f $expectedOutcome, [string]$matchedRule.governance_outcome))
            }
        }
    }
    else {
        if ($null -ne $matchedRule) {
            $status = "failed"
            [void]$failureReasons.Add(("expected no match but got rule_id '{0}'" -f [string]$matchedRule.rule_id))
        }
    }

    [void]$results.Add([pscustomobject]@{
        fixture_id = $fixtureId
        signal_type = $signalType
        should_match = $shouldMatch
        status = $status
        matched_rule_id = $(if ($null -ne $matchedRule) { [string]$matchedRule.rule_id } else { $null })
        matched_governance_outcome = $(if ($null -ne $matchedRule) { [string]$matchedRule.governance_outcome } else { $null })
        failure_reasons = @($failureReasons)
    })

    foreach ($reason in $failureReasons) {
        [void]$failures.Add(("{0}: {1}" -f $fixtureId, $reason))
    }
}

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    manifest_version = [string]$manifest.manifest_version
    total_fixtures = @($fixtureSet.fixtures).Count
    failed_fixtures = @($results | Where-Object { $_.status -eq "failed" }).Count
    results = $results
    failures = @($failures)
}

Write-Host ""
Write-Host "Governance rule fixture summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 10)

if ($summary.status -ne "passed") {
    throw "Governance rule fixtures failed."
}

Write-Host ""
Write-Host "Governance rule fixtures passed." -ForegroundColor Green
