BeforeAll {
    $script:Repo = Resolve-Path (Join-Path $PSScriptRoot '..')
    $script:Out = Join-Path $script:Repo 'tests/.out'

    function Build-Site {
        param([string]$Fixture)
        Push-Location $script:Repo
        try {
            & npx quartz build -d $Fixture -o tests/.out 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "quartz build failed for $Fixture" }
        }
        finally { Pop-Location }
    }
    function Get-Page { param([string]$Name) [IO.File]::ReadAllText((Join-Path $script:Out $Name)) }
    function Get-Index { param([string]$Html, [string]$Needle) $Html.IndexOf($Needle, [StringComparison]::Ordinal) }

    $script:MarkerRegex = 'class="[^"]*\b(explorer|graph|backlinks|search|toc|breadcrumb-container|darkmode|readermode|page-title|sidebar)\b'
}

Describe 'article page' {
    BeforeAll {
        Build-Site 'tests/fixtures/site'
        $script:Article = Get-Page 'articolo.html'
    }

    It 'orders header, cover, body and footer' {
        $h = Get-Index $Article '<header data-role="article-header"'
        $c = Get-Index $Article '<img data-role="cover"'
        $b = Get-Index $Article '<article'
        $f = Get-Index $Article '<footer data-role="site-footer"'
        $h | Should -BeGreaterThan -1
        $c | Should -BeGreaterThan $h
        $b | Should -BeGreaterThan $c
        $f | Should -BeGreaterThan $b
    }

    It 'renders title and summary escaped inside the header' {
        $start = Get-Index $Article '<header data-role="article-header"'
        $end = Get-Index $Article '<img data-role="cover"'
        $header = $Article.Substring($start, $end - $start)
        $header | Should -Match '<h1[^>]*>Prova &amp; &lt;test(&gt;|>)</h1>'
        $header | Should -Match 'data-role="summary"[^>]*>Summary (&quot;|")di prova(&quot;|")'
        $header | Should -Not -Match '<test>'
        $header | Should -Match '2026'
    }

    It 'gives the cover a valid, encoded URL that points to an emitted file' {
        $m = [regex]::Match($Article, '<img[^>]*data-role="cover"[^>]*src="([^"]+)"|<img[^>]*src="([^"]+)"[^>]*data-role="cover"')
        $m.Success | Should -BeTrue
        $src = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        $src | Should -Not -Match ' '
        $src | Should -Match '%C3%A0'
        $decoded = [uri]::UnescapeDataString($src)
        Test-Path -LiteralPath (Join-Path $script:Out $decoded) | Should -BeTrue
    }

    It 'resolves the same cover for a note in a subfolder' {
        $page = Get-Page 'cartella/annidata.html'
        $m = [regex]::Match($page, '<img[^>]*data-role="cover"[^>]*src="([^"]+)"|<img[^>]*src="([^"]+)"[^>]*data-role="cover"')
        $m.Success | Should -BeTrue
        $src = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        $decoded = [uri]::UnescapeDataString($src)
        Test-Path -LiteralPath (Join-Path $script:Out 'cartella' $decoded) | Should -BeTrue
    }

    It 'contains none of the disabled Quartz components' {
        $Article | Should -Not -Match $script:MarkerRegex
    }

    It 'points og:image and twitter:image at the emitted cover' {
        $expected = 'https://gi4mba.github.io/digital-garden/img/citt%C3%A0-1.jpg'
        $Article | Should -Match ('<meta property="og:image" content="' + [regex]::Escape($expected) + '"')
        $Article | Should -Match ('<meta name="twitter:image" content="' + [regex]::Escape($expected) + '"')
        Test-Path -LiteralPath (Join-Path $script:Out 'img/città-1.jpg') | Should -BeTrue
    }

    It 'has a top bar that links back to the home' {
        $Article | Should -Match '<nav data-role="site-nav"[^>]*><a href="./"[^>]*>Hyphae</a>'
        $nested = Get-Page 'cartella/annidata.html'
        $nested | Should -Match '<nav data-role="site-nav"[^>]*><a href="../"[^>]*>Hyphae</a>'
    }

    It 'ends the page with the thread divider inside the footer' {
        $f = Get-Index $Article '<footer data-role="site-footer"'
        $Article.Substring($f) | Should -Match 'data-role="thread"'
    }

    It 'sets a 56rem wide column with a 42rem text measure' {
        $Article | Should -Match '56rem'
        $Article | Should -Match '42rem'
    }

    It 'has a footer with the home link and the current year' {
        $f = Get-Index $Article '<footer data-role="site-footer"'
        $footer = $Article.Substring($f)
        $footer | Should -Match 'https://gi4mba\.github\.io'
        $footer | Should -Match ([string](Get-Date).Year)
    }
}

Describe 'home page' {
    BeforeAll {
        function New-Fixture {
            param([string]$Name, [object[]]$Notes)
            $dir = Join-Path ([IO.Path]::GetTempPath()) "garden-fixtures/$Name"
            if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
            New-Item -ItemType Directory -Force (Join-Path $dir 'img') | Out-Null
            Copy-Item (Join-Path $script:Repo 'tests/fixtures/site/img/*') (Join-Path $dir 'img')
            [IO.File]::WriteAllText((Join-Path $dir 'index.md'), "---`ntitle: Hyphae`n---`n")
            foreach ($n in $Notes) {
                $lines = @('---', "title: $($n.Title)", "description: Summary $($n.Title)", 'image: img/città 1.jpg')
                if ($n.Date) { $lines += "date: $($n.Date)" }
                if ($n.Pinned) { $lines += 'pinned: true' }
                $lines += @('---', 'Corpo.')
                [IO.File]::WriteAllText((Join-Path $dir "$($n.File).md"), ($lines -join "`n"))
            }
            $dir
        }
        function Get-Section {
            param([string]$Html, [string]$Name)
            $m = [regex]::Match($Html, "<section data-section=`"$Name`".*?</section>", 'Singleline')
            if ($m.Success) { $m.Value } else { $null }
        }
        function Get-Titles {
            param([string]$Section)
            if (-not $Section) { return @() }
            @([regex]::Matches($Section, 'data-role="note-title"[^>]*>([^<]+)<') | ForEach-Object { $_.Groups[1].Value })
        }

        $notes = @(
            @{ File = 'p1'; Title = 'Pin Uno'; Date = '2026-03-01'; Pinned = $true },
            @{ File = 'p2'; Title = 'Pin Due'; Date = '2026-05-01'; Pinned = $true },
            @{ File = 'n1'; Title = 'Nota Giugno'; Date = '2026-06-01' },
            @{ File = 'n2'; Title = 'Nota Febbraio'; Date = '2026-02-01' },
            @{ File = 'n3'; Title = 'Nota Senza Data' },
            @{ File = 'n4'; Title = 'Nota Alfa'; Date = '2026-06-01' }
        )
        Build-Site (New-Fixture 'home' $notes)
        $script:HomeHtml = Get-Page 'index.html'
        $script:Pinned = Get-Section $script:HomeHtml 'pinned'
        $script:List = Get-Section $script:HomeHtml 'list'
    }

    It 'shows the pinned notes newest first, each with a cover image' {
        Get-Titles $Pinned | Should -Be @('Pin Due', 'Pin Uno')
        ([regex]::Matches($Pinned, '<img')).Count | Should -Be 2
    }

    It 'lists the other notes newest first, undated last, without images' {
        Get-Titles $List | Should -Be @('Nota Alfa', 'Nota Giugno', 'Nota Febbraio', 'Nota Senza Data')
        $List | Should -Not -Match '<img'
    }

    It 'never repeats a note in both sections' {
        $both = @(Get-Titles $Pinned) | Where-Object { (Get-Titles $List) -contains $_ }
        $both | Should -BeNullOrEmpty
    }

    It 'links each note to its page' {
        $Pinned | Should -Match 'href="\./p2"'
        $List | Should -Match 'href="\./n3"'
    }

    It 'has the site name, description and footer, and no disabled components' {
        $HomeHtml | Should -Match '<h1[^>]*>Hyphae</h1>'
        $HomeHtml | Should -Match 'Appunti e articoli dal mio giardino digitale'
        $HomeHtml | Should -Match '<footer data-role="site-footer"'
        $HomeHtml | Should -Not -Match $script:MarkerRegex
    }

    It 'omits the pinned section when nothing is pinned' {
        Build-Site (New-Fixture 'home-nopins' @(@{ File = 'n1'; Title = 'Solo Lista'; Date = '2026-01-01' }))
        $html = Get-Page 'index.html'
        $html | Should -Not -Match '<section data-section="pinned"'
        Get-Titles (Get-Section $html 'list') | Should -Be @('Solo Lista')
    }

    It 'caps pinned at 4 and moves the extra pinned note to the list' {
        $many = 1..5 | ForEach-Object { @{ File = "m$_"; Title = "Pin $_"; Date = "2026-0$_-01"; Pinned = $true } }
        Build-Site (New-Fixture 'home-many' $many)
        $html = Get-Page 'index.html'
        Get-Titles (Get-Section $html 'pinned') | Should -Be @('Pin 5', 'Pin 4', 'Pin 3', 'Pin 2')
        Get-Titles (Get-Section $html 'list') | Should -Be @('Pin 1')
    }
}
