BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'Publish.Validation.ps1')

    function New-TestFile {
        param([string]$Root, [string]$Rel, [string]$Text = 'x')
        $p = Join-Path $Root $Rel
        New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
        [IO.File]::WriteAllText($p, $Text)
        $p
    }
    function New-TestNote {
        param([string]$Root, [string]$Rel, [string[]]$Front, [string]$Body = 'Corpo.', [string]$Eol = "`n")
        $text = '---' + $Eol + (($Front -join $Eol)) + $Eol + '---' + $Eol + $Body + $Eol
        if ($Front.Count -eq 0) { $text = $Body + $Eol }
        New-TestFile $Root $Rel $text | Out-Null
    }
    function New-ValidFront {
        param([string]$Image = 'img/c.jpg')
        @('title: T', 'description: D', "image: $Image", 'date: 2026-01-01')
    }
}

Describe 'Read-NoteFrontmatter' {
    It 'reads a CRLF file with quoted value containing a colon' {
        $dir = Join-Path $TestDrive 'fm1'
        New-TestNote $dir 'a.md' @('title: "Nota: la prova"', "description: 'Riga'", 'pinned: true') -Eol "`r`n"
        $fm = Read-NoteFrontmatter -Path (Join-Path $dir 'a.md')
        $fm['title'] | Should -Be 'Nota: la prova'
        $fm['description'] | Should -Be 'Riga'
        $fm['pinned'] | Should -Be 'true'
    }
    It 'returns an empty hashtable without frontmatter' {
        $dir = Join-Path $TestDrive 'fm2'
        New-TestNote $dir 'a.md' @()
        (Read-NoteFrontmatter -Path (Join-Path $dir 'a.md')).Count | Should -Be 0
    }
}

Describe 'Test-PublishNotes' {
    BeforeEach {
        $script:pub = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-TestFile $pub 'img/c.jpg' | Out-Null
    }

    It 'accepts a valid note' {
        New-TestNote $pub 'a.md' (New-ValidFront)
        $r = Test-PublishNotes -PublishDir $pub
        $r.Errors | Should -BeNullOrEmpty
        $r.Warnings | Should -BeNullOrEmpty
        $r.Notes.Count | Should -Be 1
        $r.Notes[0].Title | Should -Be 'T'
        $r.Notes[0].Pinned | Should -BeFalse
    }

    It 'reports a missing <field>' -ForEach @(
        @{ field = 'title' }, @{ field = 'description' }, @{ field = 'image' }
    ) {
        $front = (New-ValidFront) | Where-Object { $_ -notlike "$field*" }
        New-TestNote $pub 'a.md' $front
        $r = Test-PublishNotes -PublishDir $pub
        $r.Errors.Count | Should -Be 1
        $r.Errors[0] | Should -BeLike "a.md: *$field*"
    }

    It 'errors on a missing image file' {
        New-TestNote $pub 'a.md' (New-ValidFront -Image 'img/nope.jpg')
        (Test-PublishNotes -PublishDir $pub).Errors | Should -BeLike '*a.md: *nope.jpg*'
    }

    It 'accepts an image with spaces and accents' {
        New-TestFile $pub 'img/città 1.jpg' | Out-Null
        New-TestNote $pub 'a.md' (New-ValidFront -Image 'img/città 1.jpg')
        (Test-PublishNotes -PublishDir $pub).Errors | Should -BeNullOrEmpty
    }

    It 'resolves image relative to the Publish root for a note in a subfolder' {
        New-TestNote $pub 'sub/a.md' (New-ValidFront)
        (Test-PublishNotes -PublishDir $pub).Errors | Should -BeNullOrEmpty
    }

    It 'allows 4 pinned notes' {
        1..4 | ForEach-Object { New-TestNote $pub "n$_.md" ((New-ValidFront) + 'pinned: true') }
        (Test-PublishNotes -PublishDir $pub).Errors | Should -BeNullOrEmpty
    }

    It 'errors with all names when 5 notes are pinned' {
        1..5 | ForEach-Object { New-TestNote $pub "n$_.md" ((New-ValidFront) + 'pinned: true') }
        $r = Test-PublishNotes -PublishDir $pub
        $r.Errors.Count | Should -Be 1
        1..5 | ForEach-Object { $r.Errors[0] | Should -BeLike "*n$_.md*" }
    }

    It 'warns (not errors) on a missing date' {
        New-TestNote $pub 'a.md' ((New-ValidFront) | Where-Object { $_ -notlike 'date*' })
        $r = Test-PublishNotes -PublishDir $pub
        $r.Errors | Should -BeNullOrEmpty
        $r.Warnings | Should -BeLike 'a.md: *date*'
    }

    It 'warns on an unparsable date' {
        New-TestNote $pub 'a.md' (((New-ValidFront) | Where-Object { $_ -notlike 'date*' }) + 'date: 31/12/2026')
        $r = Test-PublishNotes -PublishDir $pub
        $r.Errors | Should -BeNullOrEmpty
        $r.Warnings | Should -BeLike 'a.md: *date*'
    }

    It 'warns on a wikilink to a note that is not published' {
        New-TestNote $pub 'a.md' (New-ValidFront) -Body 'Vedi [[altra-nota]].'
        (Test-PublishNotes -PublishDir $pub).Warnings | Should -BeLike 'a.md: *altra-nota*'
    }

    It 'does not warn on valid links, aliases, headings or embeds' {
        New-TestNote $pub 'a.md' (New-ValidFront) -Body 'Vedi [[b]], [[b|alias]], [[b#Sezione]] e ![[c.jpg]].'
        New-TestNote $pub 'b.md' (New-ValidFront)
        (Test-PublishNotes -PublishDir $pub).Warnings | Should -BeNullOrEmpty
    }

    It 'reports the three required fields for a note without frontmatter' {
        New-TestNote $pub 'a.md' @()
        (Test-PublishNotes -PublishDir $pub).Errors.Count | Should -Be 3
    }

    It 'ignores .obsidian and .trash' {
        New-TestNote $pub '.obsidian/x.md' @()
        New-TestNote $pub '.trash/y.md' @()
        $r = Test-PublishNotes -PublishDir $pub
        $r.Errors | Should -BeNullOrEmpty
        $r.Notes.Count | Should -Be 0
    }
}
