Set-StrictMode -Version Latest

$script:MaxPinned = 4
$script:ExcludedDirs = @('.obsidian', '.trash')

function Read-NoteFrontmatter {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $fm = @{}
    $text = [IO.File]::ReadAllText($Path).TrimStart([char]0xFEFF)
    $lines = $text -split "`r?`n"
    if ($lines.Count -eq 0 -or $lines[0].TrimEnd() -ne '---') { return $fm }

    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -eq '---') { break }
        if ($lines[$i] -match '^([A-Za-z_][\w-]*)\s*:\s*(.*)$') {
            $value = $Matches[2].Trim()
            if ($value.Length -ge 2 -and $value[0] -eq $value[-1] -and ($value[0] -eq '"' -or $value[0] -eq "'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $fm[$Matches[1].ToLowerInvariant()] = $value
        }
    }
    $fm
}

function Get-PublishNoteFiles {
    param([string]$PublishDir)
    $root = (Resolve-Path -LiteralPath $PublishDir).Path.TrimEnd('\', '/')
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md' | Where-Object {
        $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
        $segments = $rel -split '[\\/]'
        -not ($segments | Where-Object { $script:ExcludedDirs -contains $_ })
    }
}

function Test-PublishNotes {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$PublishDir)

    $root = (Resolve-Path -LiteralPath $PublishDir).Path.TrimEnd('\', '/')
    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $notes = [System.Collections.Generic.List[object]]::new()

    $files = @(Get-PublishNoteFiles -PublishDir $root)
    $stems = @{}
    foreach ($f in $files) { $stems[[IO.Path]::GetFileNameWithoutExtension($f.Name).ToLowerInvariant()] = $true }

    foreach ($f in $files) {
        $rel = ($f.FullName.Substring($root.Length).TrimStart('\', '/')) -replace '\\', '/'
        $fm = Read-NoteFrontmatter -Path $f.FullName
        $get = { param($k) if ($fm.ContainsKey($k)) { $fm[$k] } else { '' } }
        $title = & $get 'title'
        $description = & $get 'description'
        $image = & $get 'image'
        $date = & $get 'date'

        foreach ($pair in @(@('title', $title), @('description', $description), @('image', $image))) {
            if ([string]::IsNullOrWhiteSpace($pair[1])) { $errors.Add("${rel}: campo '$($pair[0])' mancante") }
        }

        if (-not [string]::IsNullOrWhiteSpace($image)) {
            $imgPath = [IO.Path]::GetFullPath((Join-Path $root $image))
            if (-not $imgPath.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
                $errors.Add("${rel}: immagine fuori da Publish: $image")
            }
            elseif (-not (Test-Path -LiteralPath $imgPath -PathType Leaf)) {
                $errors.Add("${rel}: immagine non trovata: $image")
            }
        }

        if ([string]::IsNullOrWhiteSpace($date)) {
            $warnings.Add("${rel}: campo 'date' mancante")
            $date = $null
        }
        else {
            $parsed = [datetime]::MinValue
            if (-not [datetime]::TryParseExact($date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
                $warnings.Add("${rel}: campo 'date' non valido (atteso yyyy-MM-dd): $date")
            }
        }

        $body = [IO.File]::ReadAllText($f.FullName)
        foreach ($m in [regex]::Matches($body, '(?<!!)\[\[([^\]]+)\]\]')) {
            $target = ($m.Groups[1].Value -split '\|')[0]
            $target = ($target -split '#')[0].Trim()
            if ($target -eq '') { continue }
            $leaf = ($target -split '[\\/]')[-1].ToLowerInvariant()
            if (-not $stems.ContainsKey($leaf)) {
                $warnings.Add("${rel}: link a '$target' non pubblicato")
            }
        }

        $notes.Add([pscustomobject]@{
                Path        = $rel
                Title       = $title
                Description = $description
                Image       = $image
                Date        = $date
                Pinned      = ((& $get 'pinned') -ieq 'true')
            })
    }

    $pinned = @($notes | Where-Object { $_.Pinned })
    if ($pinned.Count -gt $script:MaxPinned) {
        $errors.Add("Publish: piu' di $($script:MaxPinned) note con pinned: true ($($pinned.Count)): " + (($pinned | ForEach-Object Path) -join ', '))
    }

    [pscustomobject]@{
        Errors   = [string[]]$errors.ToArray()
        Warnings = [string[]]$warnings.ToArray()
        Notes    = $notes.ToArray()
    }
}
