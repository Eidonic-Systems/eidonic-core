param(
    [string]$EidonBaseUrl = "http://127.0.0.1:8003"
)

$ErrorActionPreference = "Stop"

$response = Invoke-RestMethod -Uri "$EidonBaseUrl/provider/warm" `
  -Method Post

$responseJson = $response | ConvertTo-Json -Depth 12
Write-Host ""
Write-Host $responseJson

if ($response.status -ne "warmed") {
    throw "Provider warmup failed. Status was '$($response.status)'."
}

if ($null -eq $response.provider) {
    throw "Provider warmup response was missing provider details."
}

if ($response.provider.ready -ne $true) {
    throw "Provider warmup did not report ready=true."
}

Write-Host "Eidon provider warmup completed." -ForegroundColor Green
