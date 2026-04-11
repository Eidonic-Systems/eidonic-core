param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$ExpectedProviderBackend = "ollama",
    [string]$ExpectedMissingModel = "definitely-missing-model"
)

$ErrorActionPreference = "Stop"

function Assert-Equal {
    param(
        [string]$Name,
        $Actual,
        $Expected
    )

    if ($Actual -ne $Expected) {
        throw "$Name failed. Expected '$Expected' but got '$Actual'."
    }
}

$warmResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" `
  -Method Post

$warmResponseJson = $warmResponse | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $warmResponseJson

Assert-Equal -Name "warm failure response status" `
  -Actual $warmResponse.status `
  -Expected "warm_failed"

Assert-Equal -Name "warm failure response service" `
  -Actual $warmResponse.service `
  -Expected "eidon-orchestrator"

if ($null -eq $warmResponse.provider) {
    throw "Missing provider object in warm failure response."
}

Assert-Equal -Name "warm failure provider backend" `
  -Actual $warmResponse.provider.backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "warm failure provider model" `
  -Actual $warmResponse.provider.model `
  -Expected $ExpectedMissingModel

Assert-Equal -Name "warm failure provider ready" `
  -Actual $warmResponse.provider.ready `
  -Expected $false

Assert-Equal -Name "warm failure error code" `
  -Actual $warmResponse.provider_error_code `
  -Expected "provider_model_missing"

Assert-Equal -Name "warm failure error message" `
  -Actual $warmResponse.provider_error_message `
  -Expected "Provider model is not available locally: $ExpectedMissingModel"

Write-Host "Provider warmup failure surface integration test passed." -ForegroundColor Green
