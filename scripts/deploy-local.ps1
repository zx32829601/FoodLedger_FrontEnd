param(
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $RepoRoot ".env"
$DockerDesktopBinPath = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin"
$ComposeScriptPath = Join-Path $PSScriptRoot "Invoke-DockerCompose.ps1"
$DefaultWebHttpPort = "8180"

function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "==> $Message"
}

function Ensure-DockerCli {
    $dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -ne $dockerCommand) {
        return
    }

    $dockerPath = Join-Path $DockerDesktopBinPath "docker.exe"
    if (Test-Path $dockerPath) {
        $env:Path = "$DockerDesktopBinPath;$env:Path"
        return
    }

    throw "Docker CLI was not found. Start Docker Desktop, or reinstall Docker Desktop and reopen the terminal."
}

function Get-EnvFileValue {
    param([string]$Name)

    if (-not (Test-Path $EnvPath)) {
        return $null
    }

    foreach ($line in Get-Content -Encoding utf8 $EnvPath) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith("#")) {
            continue
        }

        $parts = $trimmedLine.Split("=", 2)
        if ($parts.Length -eq 2 -and $parts[0].Trim() -eq $Name) {
            return $parts[1].Trim().Trim('"').Trim("'")
        }
    }

    return $null
}

function Get-DeploymentValue {
    param(
        [string]$Name,
        [string]$DefaultValue = ""
    )

    $environmentValue = [Environment]::GetEnvironmentVariable($Name)
    if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
        return $environmentValue
    }

    $envFileValue = Get-EnvFileValue -Name $Name
    if (-not [string]::IsNullOrWhiteSpace($envFileValue)) {
        return $envFileValue
    }

    return $DefaultValue
}

Push-Location $RepoRoot
try {
    Write-Step "Check Docker CLI"
    Ensure-DockerCli
    docker --version
    & $ComposeScriptPath -ArgumentList @("version")

    Write-Step "Check Docker daemon"
    docker info --format "{{.ServerVersion}}" | Out-Null

    $apiBaseUrl = Get-DeploymentValue -Name "FOOD_LEDGER_API_BASE_URL"
    if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) {
        throw "Set FOOD_LEDGER_API_BASE_URL in the environment or a local .env file before deploying."
    }

    Write-Step "Validate docker-compose.yml"
    & $ComposeScriptPath -ArgumentList @("config", "--quiet")

    Write-Step "Start local deployment"
    if ($SkipBuild) {
        & $ComposeScriptPath -ArgumentList @("up", "--detach", "--no-build", "--remove-orphans")
    }
    else {
        & $ComposeScriptPath -ArgumentList @("up", "--build", "--detach", "--remove-orphans")
    }

    Write-Step "Show container status"
    & $ComposeScriptPath -ArgumentList @("ps")

    $webHttpPort = Get-DeploymentValue -Name "FOODLEDGER_WEB_HTTP_PORT" -DefaultValue $DefaultWebHttpPort
    Write-Host ""
    Write-Host "Local deploy completed."
    Write-Host ("Website: http://localhost:{0}" -f $webHttpPort)
}
finally {
    Pop-Location
}
