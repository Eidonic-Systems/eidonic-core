param(
    [string]$RepoRoot = ".",
    [string]$EidonBaseUrl = "http://127.0.0.1:8003"
)

$ErrorActionPreference = "Stop"

function Add-Failure {
    param(
        [System.Collections.ArrayList]$Failures,
        [string]$Message
    )

    [void]$Failures.Add($Message)
}

function Get-OptionalProperty {
    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object.PSObject.Properties.Name -contains $Name) {
        return $Object.$Name
    }

    return $null
}

function Assert-HealthSurface {
    param(
        [object]$Health,
        [System.Collections.ArrayList]$Failures,
        [string]$Label,
        [switch]$RequireProviderReady
    )

    if ($null -eq $Health) {
        Add-Failure -Failures $Failures -Message ("{0} returned no health payload" -f $Label)
        return
    }

    if ([string]$Health.status -ne "ok") {
        Add-Failure -Failures $Failures -Message ("{0} health.status was not ok" -f $Label)
    }

    if ([string]$Health.artifact_store.status -ne "ok") {
        Add-Failure -Failures $Failures -Message ("{0} artifact_store.status was not ok" -f $Label)
    }

    if ([string]$Health.lineage_store.status -ne "ok") {
        Add-Failure -Failures $Failures -Message ("{0} lineage_store.status was not ok" -f $Label)
    }

    if ($null -eq $Health.provider) {
        Add-Failure -Failures $Failures -Message ("{0} health payload was missing provider details" -f $Label)
        return
    }

    if ($RequireProviderReady) {
        if ([string]$Health.provider.status -ne "ok") {
            Add-Failure -Failures $Failures -Message ("{0} provider.status was not ok after warmup" -f $Label)
        }

        if (-not [bool]$Health.provider.ready) {
            Add-Failure -Failures $Failures -Message ("{0} provider.ready was not true after warmup" -f $Label)
        }
    }
}

function Assert-WarmResponse {
    param(
        [object]$WarmResponse,
        [System.Collections.ArrayList]$Failures,
        [string]$Label
    )

    if ($null -eq $WarmResponse) {
        Add-Failure -Failures $Failures -Message ("{0} returned no payload" -f $Label)
        return
    }

    if ([string]$WarmResponse.status -ne "warmed") {
        Add-Failure -Failures $Failures -Message ("{0} did not return status=warmed" -f $Label)
    }

    if ($null -eq $WarmResponse.provider) {
        Add-Failure -Failures $Failures -Message ("{0} was missing provider details" -f $Label)
        return
    }

    if (-not [bool]$WarmResponse.provider.ready) {
        Add-Failure -Failures $Failures -Message ("{0} did not report provider.ready=true" -f $Label)
    }
}

function Assert-WarmHealthAgreement {
    param(
        [object]$WarmResponse,
        [object]$HealthResponse,
        [System.Collections.ArrayList]$Failures,
        [string]$Label
    )

    if ($null -eq $WarmResponse -or $null -eq $WarmResponse.provider) {
        return
    }

    if ($null -eq $HealthResponse -or $null -eq $HealthResponse.provider) {
        Add-Failure -Failures $Failures -Message ("{0} could not compare warm and health provider details" -f $Label)
        return
    }

    if ([bool]$WarmResponse.provider.ready -ne [bool]$HealthResponse.provider.ready) {
        Add-Failure -Failures $Failures -Message ("{0} warm and health responses disagreed on provider.ready" -f $Label)
    }

    foreach ($propertyName in @('backend', 'model', 'status')) {
        $warmValue = Get-OptionalProperty -Object $WarmResponse.provider -Name $propertyName
        $healthValue = Get-OptionalProperty -Object $HealthResponse.provider -Name $propertyName

        if ($null -ne $warmValue -and $null -ne $healthValue) {
            if ([string]$warmValue -ne [string]$healthValue) {
                Add-Failure -Failures $Failures -Message ("{0} warm and health responses disagreed on provider.{1}" -f $Label, $propertyName)
            }
        }
    }
}

Write-Host ""
Write-Host "Provider readiness invariant validation:" -ForegroundColor Yellow
Write-Host ("  base url: {0}" -f $EidonBaseUrl)

$baselineHealth = Invoke-RestMethod -Uri "$EidonBaseUrl/health" -Method Get
$firstWarm = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" -Method Post
$firstPostWarmHealth = Invoke-RestMethod -Uri "$EidonBaseUrl/health" -Method Get
$secondWarm = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" -Method Post
$secondPostWarmHealth = Invoke-RestMethod -Uri "$EidonBaseUrl/health" -Method Get

Write-Host ""
Write-Host "Baseline health payload:" -ForegroundColor Yellow
Write-Host ($baselineHealth | ConvertTo-Json -Depth 12)

Write-Host ""
Write-Host "First warm payload:" -ForegroundColor Yellow
Write-Host ($firstWarm | ConvertTo-Json -Depth 12)

Write-Host ""
Write-Host "Health after first warm:" -ForegroundColor Yellow
Write-Host ($firstPostWarmHealth | ConvertTo-Json -Depth 12)

Write-Host ""
Write-Host "Second warm payload:" -ForegroundColor Yellow
Write-Host ($secondWarm | ConvertTo-Json -Depth 12)

Write-Host ""
Write-Host "Health after second warm:" -ForegroundColor Yellow
Write-Host ($secondPostWarmHealth | ConvertTo-Json -Depth 12)

$failures = [System.Collections.ArrayList]::new()

Assert-HealthSurface -Health $baselineHealth -Failures $failures -Label 'baseline'
Assert-WarmResponse -WarmResponse $firstWarm -Failures $failures -Label 'first warm call'
Assert-HealthSurface -Health $firstPostWarmHealth -Failures $failures -Label 'post-first-warm' -RequireProviderReady
Assert-WarmHealthAgreement -WarmResponse $firstWarm -HealthResponse $firstPostWarmHealth -Failures $failures -Label 'first warm vs first post-warm health'
Assert-WarmResponse -WarmResponse $secondWarm -Failures $failures -Label 'second warm call'
Assert-HealthSurface -Health $secondPostWarmHealth -Failures $failures -Label 'post-second-warm' -RequireProviderReady
Assert-WarmHealthAgreement -WarmResponse $secondWarm -HealthResponse $secondPostWarmHealth -Failures $failures -Label 'second warm vs second post-warm health'

$summary = [ordered]@{
    status = $(if ($failures.Count -eq 0) { "passed" } else { "failed" })
    base_url = $EidonBaseUrl
    baseline_provider_status = [string](Get-OptionalProperty -Object $baselineHealth.provider -Name 'status')
    baseline_provider_ready = [bool](Get-OptionalProperty -Object $baselineHealth.provider -Name 'ready')
    first_warm_status = [string]$firstWarm.status
    first_warm_provider_ready = [bool](Get-OptionalProperty -Object $firstWarm.provider -Name 'ready')
    first_post_warm_provider_status = [string](Get-OptionalProperty -Object $firstPostWarmHealth.provider -Name 'status')
    first_post_warm_provider_ready = [bool](Get-OptionalProperty -Object $firstPostWarmHealth.provider -Name 'ready')
    second_warm_status = [string]$secondWarm.status
    second_warm_provider_ready = [bool](Get-OptionalProperty -Object $secondWarm.provider -Name 'ready')
    second_post_warm_provider_status = [string](Get-OptionalProperty -Object $secondPostWarmHealth.provider -Name 'status')
    second_post_warm_provider_ready = [bool](Get-OptionalProperty -Object $secondPostWarmHealth.provider -Name 'ready')
    failures = @($failures)
}

Write-Host ""
Write-Host "Provider readiness invariant validation summary:" -ForegroundColor Yellow
Write-Host ($summary | ConvertTo-Json -Depth 8)

if ($summary.status -ne "passed") {
    throw "Provider readiness invariant validation failed."
}

Write-Host ""
Write-Host "Provider readiness invariant validation passed." -ForegroundColor Green

