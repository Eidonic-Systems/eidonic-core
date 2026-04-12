param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$CasesPath = ".\evals\local_provider_eval_cases.json",
    [string]$OutputPath = ".\evals\local_provider_eval_results.json"
)

$ErrorActionPreference = "Stop"

function Test-ContainsAny {
    param(
        [string]$Text,
        [object[]]$Needles
    )

    foreach ($needle in $Needles) {
        if ([string]::IsNullOrWhiteSpace([string]$needle)) {
            continue
        }

        if ($Text.ToLowerInvariant().Contains(([string]$needle).ToLowerInvariant())) {
            return $true
        }
    }

    return $false
}

function Get-MissingRequired {
    param(
        [string]$Text,
        [object[]]$Needles
    )

    $missing = @()

    foreach ($needle in $Needles) {
        $value = [string]$needle
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        if (-not $Text.ToLowerInvariant().Contains($value.ToLowerInvariant())) {
            $missing += $value
        }
    }

    return $missing
}

$casesFullPath = Resolve-Path $CasesPath
$cases = Get-Content $casesFullPath -Raw | ConvertFrom-Json

$results = @()
$passedCount = 0

Write-Host ""
Write-Host "Running local provider eval surface..." -ForegroundColor Yellow

foreach ($case in $cases) {
    $payload = @{
        session_id = $case.session_id
        signal_id = $case.signal_id
        signal_type = $case.signal_type
        source = $case.source
        threshold_result = $case.threshold_result
        intent = $case.intent
        content = $case.content
    } | ConvertTo-Json -Depth 12

    $orchestrate = Invoke-RestMethod -Uri "$EidonBaseUrl/orchestrate" `
      -Method Post `
      -ContentType "application/json" `
      -Body $payload

    $artifactId = $orchestrate.artifact_id

    $artifactResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/artifacts/$artifactId" `
      -Method Get

    $artifact = $artifactResponse.artifact
    $responseText = [string]$artifact.response_text

    $missingRequired = Get-MissingRequired -Text $responseText -Needles $case.required_substrings
    $hasForbidden = Test-ContainsAny -Text $responseText -Needles $case.forbidden_substrings
    $meetsLength = $responseText.Length -ge [int]$case.min_response_length
    $isProviderFailure = $artifact.status -eq "provider_failed"

    $passed = ($missingRequired.Count -eq 0) -and (-not $hasForbidden) -and $meetsLength -and (-not $isProviderFailure)

    if ($passed) {
        $passedCount += 1
    }

    $result = [ordered]@{
        case_id = $case.case_id
        passed = $passed
        artifact_id = $artifact.artifact_id
        provider_backend = $artifact.provider_backend
        provider_model = $artifact.provider_model
        artifact_status = $artifact.status
        response_text = $responseText
        missing_required = $missingRequired
        has_forbidden = $hasForbidden
        meets_min_length = $meetsLength
    }

    $results += [pscustomobject]$result

    if ($passed) {
        Write-Host "PASS  $($case.case_id)" -ForegroundColor Green
    }
    else {
        Write-Host "FAIL  $($case.case_id)" -ForegroundColor Red
    }
}

$summary = [ordered]@{
    status = if ($passedCount -eq $results.Count) { "passed" } else { "failed" }
    total_cases = $results.Count
    passed_cases = $passedCount
    failed_cases = $results.Count - $passedCount
    results = $results
}

$summary | ConvertTo-Json -Depth 12 | Set-Content $OutputPath

Write-Host ""
Write-Host ($summary | ConvertTo-Json -Depth 12)

if ($summary.status -ne "passed") {
    throw "Local provider eval surface failed."
}

Write-Host ""
Write-Host "Local provider eval surface passed." -ForegroundColor Green
