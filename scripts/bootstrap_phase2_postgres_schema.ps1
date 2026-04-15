param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

function Get-EnvMap {
    param([string]$EnvPath)

    $map = @{}

    foreach ($line in Get-Content $EnvPath) {
        $trimmed = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed.StartsWith("#")) { continue }
        if ($trimmed -notmatch '^[A-Za-z_][A-Za-z0-9_]*=') { continue }

        $parts = $trimmed -split '=', 2
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()

        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        $map[$key] = $value
    }

    return $map
}

function Get-PostgresDsnFromEnv {
    param([hashtable]$EnvMap)

    $preferredKeys = @(
        "EIDON_ARTIFACT_STORE_DSN",
        "EIDON_LINEAGE_STORE_DSN",
        "PHASE2_PREFLIGHT_DSN",
        "DATABASE_URL",
        "POSTGRES_DSN"
    )

    foreach ($key in $preferredKeys) {
        if ($EnvMap.ContainsKey($key)) {
            $value = [string]$EnvMap[$key]
            if ($value -match '^postgres(?:ql)?://') {
                return $value
            }
        }
    }

    foreach ($key in $EnvMap.Keys) {
        $value = [string]$EnvMap[$key]
        if ($value -match '^postgres(?:ql)?://') {
            return $value
        }
    }

    throw "Could not find a PostgreSQL DSN in .env."
}

function Parse-PostgresDsn {
    param([string]$Dsn)

    $pattern = '^postgres(?:ql)?://(?<user>[^:/?#]+)(?::(?<password>[^@/?#]*))?@(?<host>[^:/?#]+)(?::(?<port>\d+))?/(?<database>[^?]+)'
    $m = [regex]::Match($Dsn, $pattern)

    if (-not $m.Success) {
        throw "Could not parse PostgreSQL DSN: $Dsn"
    }

    return [pscustomobject]@{
        user = $m.Groups["user"].Value
        password = $m.Groups["password"].Value
        host = $m.Groups["host"].Value
        port = $(if ($m.Groups["port"].Success) { $m.Groups["port"].Value } else { "5432" })
        database = $m.Groups["database"].Value
    }
}

function Get-PsqlPath {
    $psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($null -ne $psqlCmd) {
        return $psqlCmd.Source
    }

    $candidate = Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter psql.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\bin\\psql\.exe$' } |
        Select-Object -First 1

    if ($null -ne $candidate) {
        return $candidate.FullName
    }

    throw "psql.exe not found."
}

$resolvedRepoRoot = (Resolve-Path $RepoRoot).Path
$envPath = Join-Path $resolvedRepoRoot ".env"

if (-not (Test-Path $envPath)) {
    throw "Missing .env at $envPath"
}

$envMap = Get-EnvMap -EnvPath $envPath
$dsn = Get-PostgresDsnFromEnv -EnvMap $envMap
$parsed = Parse-PostgresDsn -Dsn $dsn
$psqlPath = Get-PsqlPath

$orchestratorRoot = Join-Path $resolvedRepoRoot "services\eidon-orchestrator"
$orchestratorPython = Join-Path $orchestratorRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $orchestratorPython)) {
    throw "Missing Orchestrator Python executable at $orchestratorPython"
}

Write-Host ""
Write-Host "Phase 2 PostgreSQL schema bootstrap:" -ForegroundColor Yellow
Write-Host ("  repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("  orchestrator python: {0}" -f $orchestratorPython)
Write-Host ("  psql: {0}" -f $psqlPath)
Write-Host ("  host: {0}" -f $parsed.host)
Write-Host ("  port: {0}" -f $parsed.port)
Write-Host ("  database: {0}" -f $parsed.database)

$originalEnv = @{}
foreach ($entry in $envMap.GetEnumerator()) {
    $name = [string]$entry.Key
    $value = [string]$entry.Value

    if (Test-Path ("Env:{0}" -f $name)) {
        $originalEnv[$name] = (Get-Item ("Env:{0}" -f $name)).Value
    }

    Set-Item -Path ("Env:{0}" -f $name) -Value $value
}

try {
    Push-Location $orchestratorRoot
    try {
        & $orchestratorPython -c "import app.main; print('phase2 schema bootstrap import ok')"
        if ($LASTEXITCODE -ne 0) {
            throw "Orchestrator schema bootstrap import failed."
        }
    }
    finally {
        Pop-Location
    }

    $env:PGPASSWORD = $parsed.password

    $raw = & $psqlPath -U $parsed.user -h $parsed.host -p $parsed.port -d $parsed.database -tA -F "|" -c "select to_regclass('public.artifact_records'), to_regclass('public.artifact_lineage_records');"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to verify required PostgreSQL tables."
    }

    $trimmed = ($raw | Out-String).Trim()
    $parts = $trimmed -split '\|', 2

    $artifactTable = if ($parts.Count -ge 1) { $parts[0].Trim() } else { "" }
    $lineageTable = if ($parts.Count -ge 2) { $parts[1].Trim() } else { "" }

    if ($artifactTable -ne "artifact_records" -or $lineageTable -ne "artifact_lineage_records") {
        throw "Required PostgreSQL tables are missing after schema bootstrap."
    }

    $summary = [ordered]@{
        status = "passed"
        database = $parsed.database
        artifact_table = $artifactTable
        lineage_table = $lineageTable
        orchestrator_python = $orchestratorPython
    }

    Write-Host ""
    Write-Host ($summary | ConvertTo-Json -Depth 6)
    Write-Host ""
    Write-Host "Phase 2 PostgreSQL schema bootstrap passed." -ForegroundColor Green
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

    foreach ($key in $envMap.Keys) {
        $name = [string]$key
        if ($originalEnv.ContainsKey($name)) {
            Set-Item -Path ("Env:{0}" -f $name) -Value $originalEnv[$name]
        }
        else {
            Remove-Item ("Env:{0}" -f $name) -ErrorAction SilentlyContinue
        }
    }
}
