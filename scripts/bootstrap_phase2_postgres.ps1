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
        "PHASE2_PREFLIGHT_DSN",
        "EIDON_ARTIFACT_STORE_DSN",
        "EIDON_LINEAGE_STORE_DSN",
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

$targetDatabase = $parsed.database
$maintenanceDatabase = "postgres"

Write-Host ""
Write-Host "Phase 2 PostgreSQL bootstrap:" -ForegroundColor Yellow
Write-Host ("  psql: {0}" -f $psqlPath)
Write-Host ("  host: {0}" -f $parsed.host)
Write-Host ("  port: {0}" -f $parsed.port)
Write-Host ("  user: {0}" -f $parsed.user)
Write-Host ("  target database: {0}" -f $targetDatabase)

$env:PGPASSWORD = $parsed.password

try {
    $exists = & $psqlPath -U $parsed.user -h $parsed.host -p $parsed.port -d $maintenanceDatabase -tAc "select 1 from pg_database where datname = '$targetDatabase';"
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL reachability check failed."
    }

    $existsTrimmed = ($exists | Out-String).Trim()

    if ($existsTrimmed -eq "1") {
        $summary = [ordered]@{
            status = "passed"
            action = "already_exists"
            database = $targetDatabase
            host = $parsed.host
            port = $parsed.port
            user = $parsed.user
        }

        Write-Host ""
        Write-Host ($summary | ConvertTo-Json -Depth 6)
        Write-Host ""
        Write-Host "Phase 2 PostgreSQL bootstrap passed." -ForegroundColor Green
        exit 0
    }

    & $psqlPath -U $parsed.user -h $parsed.host -p $parsed.port -d $maintenanceDatabase -c "CREATE DATABASE `"$targetDatabase`";"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create database $targetDatabase."
    }

    $summary = [ordered]@{
        status = "passed"
        action = "created"
        database = $targetDatabase
        host = $parsed.host
        port = $parsed.port
        user = $parsed.user
    }

    Write-Host ""
    Write-Host ($summary | ConvertTo-Json -Depth 6)
    Write-Host ""
    Write-Host "Phase 2 PostgreSQL bootstrap passed." -ForegroundColor Green
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
