#requires -Version 7
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PublishDir,
    [string]$RepoDir = (Split-Path $PSScriptRoot -Parent)
)

. (Join-Path $PSScriptRoot 'Publish.Validation.ps1')
. (Join-Path $PSScriptRoot 'Publish.Sync.ps1')

if (-not $PublishDir) {
    $configPath = Join-Path $PSScriptRoot 'publish.config.json'
    if (-not (Test-Path $configPath)) {
        Write-Host "Manca publish.config.json (vedi publish.config.example.json) o il parametro -PublishDir."
        exit 1
    }
    $PublishDir = (Get-Content $configPath -Raw | ConvertFrom-Json).publishDir
}

exit (Invoke-Publish -PublishDir $PublishDir -RepoDir $RepoDir -WhatIf:$WhatIfPreference)
