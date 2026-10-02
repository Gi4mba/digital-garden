# Hyphae — digital garden

Blog personale su [Quartz 5](https://quartz.jzhao.xyz/), pubblicato su GitHub Pages: https://gi4mba.github.io/digital-garden/

Le note vivono nel vault Obsidian, nella cartella `Publish/`. `scripts/publish.ps1` le valida, le copia in `content/`, fa commit e push; una GitHub Action costruisce il sito.

## Setup (una volta)

1. PowerShell 7, Node >= 22, git.
2. `copy scripts\publish.config.example.json scripts\publish.config.json` e imposta `publishDir` sul percorso di `Publish/`.
3. Su GitHub: Settings → Pages → Source "GitHub Actions".
4. In ogni nota da pubblicare: `title`, `description`, `image` (relativo a `Publish/`); opzionali `date: yyyy-MM-dd` e `pinned: true` (max 4).

## Pubblicare

```powershell
pwsh scripts/publish.ps1 -WhatIf   # anteprima, non tocca nulla
pwsh scripts/publish.ps1           # valida, copia, commit, push
```

Il repo locale deve stare sul branch `main` (lo script rifiuta altrimenti: è quello che fa partire il deploy). Se un push fallisce, rilancia lo script: reinvia i commit rimasti indietro.

La home (`content/index.md`) appartiene al repo e non viene toccata dal mirror. Test: `Invoke-Pester tests/` (Pester >= 5.5). Anteprima locale: `npx quartz build --serve -d content`.
