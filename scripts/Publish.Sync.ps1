Set-StrictMode -Version Latest

# robocopy options shared by the real mirror and the -WhatIf listing.
# index.md is repo-owned (the home page) and must survive /MIR purging.
$script:RobocopyFilters = @('/XD', '.obsidian', '.trash', '/XF', 'index.md', 'desktop.ini', 'Thumbs.db')

function Assert-PublishDir {
    param([string]$PublishDir)
    if (-not (Test-Path -LiteralPath $PublishDir -PathType Container)) {
        throw "Cartella Publish non trovata: $PublishDir"
    }
    if (-not @(Get-PublishNoteFiles -PublishDir $PublishDir).Count) {
        throw "Nessuna nota .md in ${PublishDir}: mi fermo per non svuotare il sito."
    }
}

function Sync-PublishContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PublishDir,
        [Parameter(Mandatory)][string]$ContentDir
    )
    Assert-PublishDir -PublishDir $PublishDir
    New-Item -ItemType Directory -Force $ContentDir | Out-Null
    & robocopy $PublishDir $ContentDir /MIR /NJH /NJS /NP /NFL /NDL @script:RobocopyFilters | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy fallito (exit code $LASTEXITCODE)" }
}

function Invoke-Publish {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)][string]$PublishDir,
        [Parameter(Mandatory)][string]$RepoDir
    )

    $contentDir = Join-Path $RepoDir 'content'

    try { Assert-PublishDir -PublishDir $PublishDir }
    catch { Write-Host "ERRORE: $($_.Exception.Message)"; return 1 }

    $result = Test-PublishNotes -PublishDir $PublishDir
    foreach ($w in $result.Warnings) { Write-Host "AVVISO: $w" }
    if ($result.Errors.Count) {
        foreach ($e in $result.Errors) { Write-Host "ERRORE: $e" }
        Write-Host "Pubblicazione annullata: correggi gli errori sopra."
        return 1
    }

    if ($WhatIfPreference) {
        Write-Host "[WhatIf] Modifiche previste in content/ (nessun file toccato):"
        & robocopy $PublishDir $contentDir /MIR /L /NJH /NJS /NP /NDL @script:RobocopyFilters |
            Where-Object { $_.Trim() } | ForEach-Object { Write-Host "  $($_.Trim())" }
        return 0
    }

    Sync-PublishContent -PublishDir $PublishDir -ContentDir $contentDir

    & git -C $RepoDir add -A -- content 2>&1 | Out-Null
    & git -C $RepoDir diff --cached --quiet -- content 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "Nessuna modifica da pubblicare."; return 0 }

    $changes = @(& git -C $RepoDir diff --cached --name-status -- content)
    Write-Host "File che diventano pubblici:"
    $changes | ForEach-Object { Write-Host "  $_" }

    $updated = @($changes | Where-Object { $_ -match '^[AMR]\S*\t.*\.md$' }).Count
    $removed = @($changes | Where-Object { $_ -match '^D\t.*\.md$' }).Count
    $message = "publish: $updated aggiornate, $removed rimosse"

    & git -C $RepoDir commit -m $message -- content 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "ERRORE: git commit fallito."; return 2 }

    & git -C $RepoDir push origin HEAD 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRORE: push fallito. Il commit locale resta: controlla rete/credenziali e rilancia lo script."
        return 2
    }
    Write-Host "Pubblicato: $message"
    return 0
}
