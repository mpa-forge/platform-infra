param(
    [switch]$KeepRunning
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $repoRoot "local/compose.yml"
$composeArgs = @(
    "compose",
    "-f", $composeFile,
    "--profile", "frontend-support",
    "--profile", "api-support"
)

function Invoke-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & docker @composeArgs @Arguments
}

function Wait-ForHttpOk {
    param(
        [string]$Name,
        [string]$Uri,
        [string]$ExpectedBody = "",
        [int]$MaxAttempts = 30
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $body = (& curl.exe --silent --show-error --fail $Uri).Trim()
            if ($ExpectedBody -eq "" -or $body -eq $ExpectedBody) {
                Write-Host "$Name check passed"
                return
            }
        } catch {
        }

        Start-Sleep -Seconds 2
    }

    throw "$Name check failed for $Uri"
}

try {
    Invoke-Compose down --remove-orphans | Out-Null
    Invoke-Compose up -d --build --wait --remove-orphans postgres frontend-web backend-api | Out-Null

    Write-Host "postgres health check passed"
    Wait-ForHttpOk -Name "frontend" -Uri "http://localhost:3000/healthz"
    Wait-ForHttpOk -Name "backend-api" -Uri "http://localhost:8080/healthz" -ExpectedBody "ok"

    Write-Host "Local smoke test passed"
} finally {
    if (-not $KeepRunning) {
        Invoke-Compose down --remove-orphans | Out-Null
    }
}
