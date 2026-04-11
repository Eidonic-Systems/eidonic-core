param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003",
    [string]$ExpectedProviderBackend = "ollama",
    [string]$ExpectedProviderModel = "gemma3n:e4b"
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

$preHealth = Invoke-RestMethod -Uri "$EidonBaseUrl/health" `
  -Method Get

$preHealthJson = $preHealth | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $preHealthJson

if ($null -eq $preHealth.provider) {
    throw "Missing provider object in pre-warm health response."
}

Assert-Equal -Name "pre-warm provider backend" `
  -Actual $preHealth.provider.backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "pre-warm provider model" `
  -Actual $preHealth.provider.model `
  -Expected $ExpectedProviderModel

Assert-Equal -Name "pre-warm provider ready" `
  -Actual $preHealth.provider.ready `
  -Expected $false

$warmResponse = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" `
  -Method Post

$warmResponseJson = $warmResponse | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $warmResponseJson

Assert-Equal -Name "warm response status" `
  -Actual $warmResponse.status `
  -Expected "warmed"

if ($null -eq $warmResponse.provider) {
    throw "Missing provider object in warm response."
}

Assert-Equal -Name "warm response provider backend" `
  -Actual $warmResponse.provider.backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "warm response provider model" `
  -Actual $warmResponse.provider.model `
  -Expected $ExpectedProviderModel

Assert-Equal -Name "warm response provider ready" `
  -Actual $warmResponse.provider.ready `
  -Expected $true

$postHealth = Invoke-RestMethod -Uri "$EidonBaseUrl/health" `
  -Method Get

$postHealthJson = $postHealth | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $postHealthJson

if ($null -eq $postHealth.provider) {
    throw "Missing provider object in post-warm health response."
}

Assert-Equal -Name "post-warm provider backend" `
  -Actual $postHealth.provider.backend `
  -Expected $ExpectedProviderBackend

Assert-Equal -Name "post-warm provider model" `
  -Actual $postHealth.provider.model `
  -Expected $ExpectedProviderModel

Assert-Equal -Name "post-warm provider ready" `
  -Actual $postHealth.provider.ready `
  -Expected $true

Write-Host "Provider warmup surface integration test passed." -ForegroundColor Green
