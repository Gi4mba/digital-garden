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
            # An array becomes a YAML list (as Obsidian writes it); a string stays inline.
            if ($n.Tags -is [array]) { $lines += 'tags:'; $lines += @($n.Tags | ForEach-Object { "  - $_" }) }
            elseif ($n.Tags) { $lines += "tags: $($n.Tags)" }
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
    function Get-TagCards {
        param([string]$Html)
        @([regex]::Matches($Html, '<details data-role="tag-card".*?</details>', 'Singleline') | ForEach-Object {
                $card = $_.Value
                [pscustomobject]@{
                    Name   = [regex]::Match($card, 'data-role="tag-name"[^>]*>([^<]+)<').Groups[1].Value
                    Total  = [regex]::Match($card, 'data-role="tag-count"[^>]*>([^<]+)<').Groups[1].Value
                    Titles = Get-Titles $card
                }
            })
    }

    $script:MarkerRegex ='class="[^"]*\b(explorer|graph|backlinks|search|toc|breadcrumb-container|darkmode|readermode|page-title|sidebar)\b'
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
        $header | Should -Match '1 September 2026'
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
        $Article | Should -Match '<nav data-role="site-nav"[^>]*><a href="./"[^>]*>Home</a>'
        $nested = Get-Page 'cartella/annidata.html'
        $nested | Should -Match '<nav data-role="site-nav"[^>]*><a href="../"[^>]*>Home</a>'
    }

    It 'ends the page with the thread divider inside the footer' {
        $f = Get-Index $Article '<footer data-role="site-footer"'
        $Article.Substring($f) | Should -Match 'data-role="thread"[^>]*preserveAspectRatio="none"|preserveAspectRatio="none"[^>]*data-role="thread"'
    }

    It 'lets the text fill the whole 56rem column' {
        $Article | Should -Match '56rem'
        $Article | Should -Not -Match '42rem'
    }

    It 'has the growing-thread progress bar with its script' {
        $Article | Should -Match '<div data-role="progress"'
        $Article | Should -Match 'stroke-dashoffset'
    }

    It 'fills each line of summary and body text up to the column edge' {
        $Article | Should -Match 'text-wrap: wrap'
    }

    It 'draws the progress thread as one continuous stroke' {
        $Article | Should -Not -Match '<path data-main[^>]*vector-effect'
        $Article | Should -Match '<path data-main[^>]*stroke-linecap="butt"'
    }

    It 'looks up the headings when laying out, not while the page is still being parsed' {
        $Article | Should -Match 'function layout\(\)\{var heads='
    }

    It 'keeps a heading close to its text when the author puts a rule under it' {
        $Article | Should -Match ':is\(h2, h3\) \+ hr \{[^}]*margin: 0 0 1\.25rem'
    }

    It 'themes keyboard focus, selection, scrollbars and smooth scroll for every page' {
        $Article | Should -Match 'a:focus-visible'
        $Article | Should -Match ':root\[saved-theme="dark"\] \{\s*color-scheme: dark'
        $Article | Should -Match '::selection \{[^}]*color: var\(--dark\)'
        $Article | Should -Match 'prefers-reduced-motion: reduce\)\s*\{\s*html \{\s*scroll-behavior: auto'
    }

    It 'treats the cover as decoration next to the title' {
        # Preact serialises alt="" as a bare `alt`; both mean an empty text alternative.
        $Article | Should -Match '<img data-role="cover"[^>]*\balt(="")?[\s/>]'
        $Article | Should -Not -Match '<img data-role="cover"[^>]*\balt="[^"]'
    }

    It 'has no network background on article pages' {
        $Article | Should -Not -Match '<svg data-role="network"'
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

    It 'draws the faint network behind the home header and no progress bar' {
        $HomeHtml | Should -Match '<svg data-role="network"'
        ([regex]::Matches($HomeHtml, '<circle')).Count | Should -BeGreaterThan 20
        $HomeHtml | Should -Not -Match '<div data-role="progress"'
    }

    It 'features only the newest pinned note' {
        ([regex]::Matches($Pinned, 'data-featured="true"')).Count | Should -Be 1
        $Pinned | Should -Match '<li data-role="note" data-featured="true"[^>]*>(?:(?!</li>).)*Pin Due'
        $List | Should -Not -Match 'data-featured'
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

    It 'styles the note titles as visible links (accent colour, underlined)' {
        $HomeHtml | Should -Match '\[data-role="note-title"\]\s*\{[^}]*color: var\(--secondary\)[^}]*text-decoration: underline'
    }

    It 'gives covers a quiet placeholder and no stray top margin' {
        $HomeHtml | Should -Match 'img\[data-role="card-cover"\] \{[^}]*margin: 0 0 0\.9rem[^}]*background: var\(--lightgray\)'
    }

    It 'omits the tags section when no tag reaches 3 notes' {
        $HomeHtml | Should -Not -Match '<section data-section="tags"'
    }

    It 'links each note to its page' {
        $Pinned | Should -Match 'href="\./p2"'
        $List | Should -Match 'href="\./n3"'
    }

    It 'has the site name, description and footer, and no disabled components' {
        $HomeHtml | Should -Match '<h1[^>]*>Hyphae</h1>'
        $HomeHtml | Should -Match 'The visible part is the post. The network underneath is how I think.'
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

Describe 'home tag cards' {
    BeforeAll {
        $notes = @(
            @{ File = 'a1'; Title = 'Mesh Uno'; Date = '2026-01-01'; Tags = @('mesh') },
            @{ File = 'a2'; Title = 'Mesh Due'; Date = '2026-02-01'; Tags = 'Mesh' },
            @{ File = 'a3'; Title = 'Mesh Pin'; Date = '2026-03-01'; Tags = @('mesh', 'rust'); Pinned = $true },
            @{ File = 'a4'; Title = 'Rust Solo'; Date = '2026-04-01'; Tags = @('rust') },
            @{ File = 'a5'; Title = 'Smart Uno'; Date = '2026-05-01'; Tags = @('Smart Contracts', 'mesh') },
            @{ File = 'a6'; Title = 'Smart Due'; Date = '2026-06-01'; Tags = @('Smart Contracts') },
            @{ File = 'a7'; Title = 'Smart Tre'; Date = '2026-07-01'; Tags = @('smart contracts') },
            @{ File = 'a8'; Title = 'Senza Tag' }
        )
        Build-Site (New-Fixture 'home-tags' $notes)
        $script:Html = Get-Page 'index.html'
    }

    It 'orders the home as featured, tags, posts' {
        $p = Get-Index $Html '<section data-section="pinned"'
        $t = Get-Index $Html '<section data-section="tags"'
        $l = Get-Index $Html '<section data-section="list"'
        $t | Should -BeGreaterThan $p
        $l | Should -BeGreaterThan $t
    }

    It 'shows one card per tag with at least 3 notes, most notes first' {
        $cards = Get-TagCards $Html
        $cards.Name | Should -Be @('mesh', 'smart-contracts')
        $cards.Total | Should -Be @('(4)', '(3)')
    }

    It 'lists the notes of each card newest first' {
        $cards = Get-TagCards $Html
        $cards[0].Titles | Should -Be @('Smart Uno', 'Mesh Pin', 'Mesh Due', 'Mesh Uno')
        $cards[1].Titles | Should -Be @('Smart Tre', 'Smart Due', 'Smart Uno')
    }

    It 'keeps carded notes out of Posts and pinned notes in Featured' {
        Get-Titles (Get-Section $Html 'pinned') | Should -Be @('Mesh Pin')
        Get-Titles (Get-Section $Html 'list') | Should -Be @('Rust Solo', 'Senza Tag')
    }

    It 'renders closed native disclosures and no tag pages' {
        $Html | Should -Match '<details data-role="tag-card"(?![^>]*\bopen\b)[^>]*><summary'
        Test-Path (Join-Path $script:Out 'tags') | Should -BeFalse
    }

    It 'eases the card width back on close instead of snapping' {
        $Html | Should -Match '\[data-section="tags"\] > ul > li \{[^}]*transition:\s*flex-basis'
    }

    It 'animates the opening and disables it for reduced motion' {
        $Html | Should -Match '::details-content'
        $Html | Should -Match 'prefers-reduced-motion: reduce\)\s*\{\s*[^{}]*details-content'
    }
}
