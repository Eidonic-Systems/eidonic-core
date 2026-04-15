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

function Get-TableColumns {
    param(
        [string]$PsqlPath,
        [pscustomobject]$ParsedDsn,
        [string]$TableName
    )

    $sql = "select column_name from information_schema.columns where table_schema = 'public' and table_name = '$TableName' order by ordinal_position;"
    $raw = & $PsqlPath -U $ParsedDsn.user -h $ParsedDsn.host -p $ParsedDsn.port -d $ParsedDsn.database -tA -c $sql

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to read columns for table $TableName."
    }

    $lines = @($raw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
    return $lines
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

$requiredArtifactColumns = @(
    "artifact_id",
    "session_id",
    "signal_id",
    "storage_backend",
    "provider_backend",
    "provider_model",
    "provider_status",
    "provider_route_mode",
    "provider_route_reason",
    "provider_error_code",
    "provider_error_message",
    "governance_outcome",
    "governance_reason",
    "governance_rule_id",
    "governance_manifest_version",
    "status",
    "response_text",
    "created_at"
)

$requiredLineageColumns = @(
    "lineage_id",
    "artifact_id",
    "session_id",
    "signal_id",
    "artifact_storage_backend",
    "artifact_provider_backend",
    "artifact_provider_model",
    "artifact_provider_status",
    "artifact_provider_route_mode",
    "artifact_provider_route_reason",
    "artifact_provider_error_code",
    "artifact_provider_error_message",
    "artifact_governance_outcome",
    "artifact_governance_reason",
    "artifact_governance_rule_id",
    "artifact_governance_manifest_version",
    "artifact_kind",
    "created_at"
)

Write-Host ""
Write-Host "Phase 2 PostgreSQL schema drift validation:" -ForegroundColor Yellow
Write-Host ("  psql: {0}" -f $psqlPath)
Write-Host ("  host: {0}" -f $parsed.host)
Write-Host ("  port: {0}" -f $parsed.port)
Write-Host ("  database: {0}" -f $parsed.database)

$env:PGPASSWORD = $parsed.password

try {
    $artifactColumns = Get-TableColumns -PsqlPath $psqlPath -ParsedDsn $parsed -TableName "artifact_records"
    $lineageColumns = Get-TableColumns -PsqlPath $psqlPath -ParsedDsn $parsed -TableName "artifact_lineage_records"

    $missingArtifactColumns = @($requiredArtifactColumns | Where-Object { $_ -notin $artifactColumns })
    $missingLineageColumns = @($requiredLineageColumns | Where-Object { $_ -notin $lineageColumns })

    $summary = [ordered]@{
        status = $(if ($missingArtifactColumns.Count -eq 0 -and $missingLineageColumns.Count -eq 0) { "passed" } else { "failed" })
        database = $parsed.database
        artifact_table = "artifact_records"
        artifact_column_count = $artifactColumns.Count
        artifact_missing_columns = $missingArtifactColumns
        lineage_table = "artifact_lineage_records"
        lineage_column_count = $lineageColumns.Count
        lineage_missing_columns = $missingLineageColumns
    }

    Write-Host ""
    Write-Host ($summary | ConvertTo-Json -Depth 8)

    if ($summary.status -ne "passed") {
        throw "Phase 2 PostgreSQL schema drift validation failed."
    }

    Write-Host ""
    Write-Host "Phase 2 PostgreSQL schema drift validation passed." -ForegroundColor Green
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
