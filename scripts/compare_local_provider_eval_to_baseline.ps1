param(
    [string]$CurrentPath = ".\evals\local_provider_eval_results.json",
    [string]$BaselinePath = ".\evals\baselines\local_provider_eval_baseline.json"
)

$ErrorActionPreference = "Stop"

function Index-ResultsByCaseId {
    param(
        [object[]]$Results
    )

    $map = @{}

    foreach ($result in $Results) {
        $caseId = [string]$result.case_id
        if ([string]::IsNullOrWhiteSpace($caseId)) {
            continue
        }

        $map[$caseId] = $result
    }

    return $map
}

$currentFullPath = Resolve-Path $CurrentPath
$baselineFullPath = Resolve-Path $BaselinePath

$current = Get-Content $currentFullPath -Raw | ConvertFrom-Json
$baseline = Get-Content $baselineFullPath -Raw | ConvertFrom-Json

$currentMap = Index-ResultsByCaseId -Results $current.results
$baselineMap = Index-ResultsByCaseId -Results $baseline.results

$allCaseIds = @($baselineMap.Keys + $currentMap.Keys | Sort-Object -Unique)

$comparisons = @()
$regressions = 0

Write-Host ""
Write-Host "Comparing local provider eval results to baseline..." -ForegroundColor Yellow

foreach ($caseId in $allCaseIds) {
    $base = $baselineMap[$caseId]
    $curr = $currentMap[$caseId]

    if ($null -eq $base) {
        $comparisons += [pscustomobject]@{
            case_id = $caseId
            comparison = "new_case"
            baseline_passed = $null
            current_passed = $curr.passed
            response_changed = $true
        }
        Write-Host "NEW   $caseId" -ForegroundColor Yellow
        continue
    }

    if ($null -eq $curr) {
        $comparisons += [pscustomobject]@{
            case_id = $caseId
            comparison = "missing_current_case"
            baseline_passed = $base.passed
            current_passed = $null
            response_changed = $true
        }
        $regressions += 1
        Write-Host "MISS  $caseId" -ForegroundColor Red
        continue
    }

    $responseChanged = ([string]$base.response_text) -ne ([string]$curr.response_text)
    $comparison = "unchanged"

    if (($base.passed -eq $true) -and ($curr.passed -eq $false)) {
        $comparison = "regressed"
        $regressions += 1
        Write-Host "REG   $caseId" -ForegroundColor Red
    }
    elseif (($base.passed -eq $false) -and ($curr.passed -eq $true)) {
        $comparison = "improved"
        Write-Host "IMPR  $caseId" -ForegroundColor Green
    }
    elseif ($responseChanged) {
        $comparison = "response_changed"
        Write-Host "CHG   $caseId" -ForegroundColor Yellow
    }
    else {
        Write-Host "SAME  $caseId" -ForegroundColor Green
    }

    $comparisons += [pscustomobject]@{
        case_id = $caseId
        comparison = $comparison
        baseline_passed = $base.passed
        current_passed = $curr.passed
        response_changed = $responseChanged
        baseline_provider_backend = $base.provider_backend
        current_provider_backend = $curr.provider_backend
        baseline_provider_model = $base.provider_model
        current_provider_model = $curr.provider_model
        baseline_response_text = $base.response_text
        current_response_text = $curr.response_text
    }
}

$summary = [ordered]@{
    status = if ($regressions -eq 0) { "passed" } else { "failed" }
    baseline_status = $baseline.status
    current_status = $current.status
    total_cases = $allCaseIds.Count
    regressions = $regressions
    comparisons = $comparisons
}

Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 12)

if ($summary.status -ne "passed") {
    throw "Local provider eval baseline comparison failed."
}

Write-Host ""
Write-Host "Local provider eval baseline comparison passed." -ForegroundColor Green
