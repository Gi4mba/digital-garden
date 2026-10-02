BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'Publish.Validation.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'Publish.Sync.ps1')

    function Invoke-Git { param([string]$Dir) & git -C $Dir @args 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { throw "git $args failed in $Dir" } }
    function Get-Git { param([string]$Dir) (& git -C $Dir @args 2>&1) -join "`n" }

    function New-Env {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $e = @{ Root = $root; Remote = Join-Path $root 'remote.git'; Repo = Join-Path $root 'repo'; Pub = Join-Path $root 'Publish' }
        New-Item -ItemType Directory -Force $e.Remote, $e.Repo, (Join-Path $e.Repo 'content'), (Join-Path $e.Pub 'img') | Out-Null
        & git init --bare -b main $e.Remote 2>&1 | Out-Null
        & git init -b main $e.Repo 2>&1 | Out-Null
        Invoke-Git $e.Repo config user.name tester
        Invoke-Git $e.Repo config user.email t@example.com
        Invoke-Git $e.Repo config core.autocrlf false
        Set-Content (Join-Path $e.Repo 'content/index.md') "---`ntitle: Home`n---`n"
        Invoke-Git $e.Repo add -A
        Invoke-Git $e.Repo commit -m init
        Invoke-Git $e.Repo remote add origin $e.Remote
        Invoke-Git $e.Repo push -u origin main
        [IO.File]::WriteAllText((Join-Path $e.Pub 'img/c.jpg'), 'jpg')
        $e
    }
    function Add-Note {
        param($e, [string]$Rel, [string[]]$Extra = @())
        $text = (@('---', 'title: T', 'description: D', 'image: img/c.jpg', 'date: 2026-01-01') + $Extra + @('---', 'Corpo.')) -join "`n"
        $p = Join-Path $e.Pub $Rel
        New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
        [IO.File]::WriteAllText($p, $text)
    }
    function Invoke-PublishCapture {
        param([hashtable]$Params)
        $r = Invoke-Publish @Params 6>&1
        [pscustomobject]@{
            Code = ($r | Where-Object { $_ -is [int] } | Select-Object -Last 1)
            Text = (($r | Where-Object { $_ -is [System.Management.Automation.InformationRecord] }) -join "`n")
        }
    }
    function Get-Commits { param($e) [int](Get-Git $e.Repo rev-list --count HEAD) }
}

Describe 'Invoke-Publish' {
    It 'publishes a valid note: mirror, commit message, push' {
        $e = New-Env
        Add-Note $e 'a.md'
        $r = Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo }
        $r.Code | Should -Be 0
        Test-Path (Join-Path $e.Repo 'content/a.md') | Should -BeTrue
        Test-Path (Join-Path $e.Repo 'content/img/c.jpg') | Should -BeTrue
        (Get-Git $e.Repo log -1 --format=%s) | Should -Be 'publish: 1 aggiornate, 0 rimosse'
        (Get-Git $e.Remote log -1 --format=%s main) | Should -Be 'publish: 1 aggiornate, 0 rimosse'
        $r.Text | Should -BeLike '*content/a.md*'
    }

    It 'keeps the repo-owned content/index.md' {
        $e = New-Env
        Add-Note $e 'a.md'
        Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo } | Out-Null
        Test-Path (Join-Path $e.Repo 'content/index.md') | Should -BeTrue
    }

    It 'does not commit when nothing changed' {
        $e = New-Env
        Add-Note $e 'a.md'
        Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo } | Out-Null
        $before = Get-Commits $e
        $r = Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo }
        $r.Code | Should -Be 0
        Get-Commits $e | Should -Be $before
    }

    It 'removes a deleted note from content' {
        $e = New-Env
        Add-Note $e 'a.md'; Add-Note $e 'b.md'
        Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo } | Out-Null
        Remove-Item (Join-Path $e.Pub 'b.md')
        $r = Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo }
        $r.Code | Should -Be 0
        Test-Path (Join-Path $e.Repo 'content/b.md') | Should -BeFalse
        (Get-Git $e.Repo log -1 --format=%s) | Should -Be 'publish: 0 aggiornate, 1 rimosse'
    }

    It 'stops with code 1 and changes nothing when validation fails' {
        $e = New-Env
        Add-Note $e 'a.md'
        [IO.File]::WriteAllText((Join-Path $e.Pub 'bad.md'), "---`ntitle: X`n---`n")
        $before = Get-Commits $e
        $r = Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo }
        $r.Code | Should -Be 1
        $r.Text | Should -BeLike '*bad.md*'
        Test-Path (Join-Path $e.Repo 'content/a.md') | Should -BeFalse
        Get-Commits $e | Should -Be $before
    }

    It 'refuses a missing or empty Publish folder and leaves content intact' {
        $e = New-Env
        Add-Note $e 'a.md'
        Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo } | Out-Null
        $empty = Join-Path $e.Root 'Vuota'
        New-Item -ItemType Directory $empty | Out-Null
        foreach ($dir in @($empty, (Join-Path $e.Root 'NonEsiste'))) {
            $r = Invoke-PublishCapture @{ PublishDir = $dir; RepoDir = $e.Repo }
            $r.Code | Should -Not -Be 0
            Test-Path (Join-Path $e.Repo 'content/a.md') | Should -BeTrue
        }
    }

    It 'does not copy .obsidian into content' {
        $e = New-Env
        Add-Note $e 'a.md'
        New-Item -ItemType Directory (Join-Path $e.Pub '.obsidian') | Out-Null
        Set-Content (Join-Path $e.Pub '.obsidian/x.md') 'x'
        Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo } | Out-Null
        Test-Path (Join-Path $e.Repo 'content/.obsidian') | Should -BeFalse
    }

    It '-WhatIf lists planned changes and touches nothing' {
        $e = New-Env
        Add-Note $e 'a.md'
        $before = Get-Commits $e
        $r = Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo; WhatIf = $true }
        $r.Code | Should -Be 0
        $r.Text | Should -BeLike '*a.md*'
        Test-Path (Join-Path $e.Repo 'content/a.md') | Should -BeFalse
        Get-Commits $e | Should -Be $before
    }

    It 'returns code 2 and keeps the local commit when push fails' {
        $e = New-Env
        Add-Note $e 'a.md'
        Invoke-Git $e.Repo remote set-url origin (Join-Path $e.Root 'nope.git')
        $before = Get-Commits $e
        $r = Invoke-PublishCapture @{ PublishDir = $e.Pub; RepoDir = $e.Repo }
        $r.Code | Should -Be 2
        Get-Commits $e | Should -Be ($before + 1)
        $r.Text | Should -BeLike '*rilanci*'
    }
}
