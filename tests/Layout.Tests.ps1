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

    It 'has a footer with the home link and the current year' {
        $f = Get-Index $Article '<footer data-role="site-footer"'
        $footer = $Article.Substring($f)
        $footer | Should -Match 'https://gi4mba\.github\.io'
        $footer | Should -Match ([string](Get-Date).Year)
    }
}
