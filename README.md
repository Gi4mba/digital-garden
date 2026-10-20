# Hyphae — digital garden

Blog personale su [Quartz 5](https://quartz.jzhao.xyz/), pubblicato su GitHub Pages: https://gi4mba.github.io/digital-garden/

Le note vivono nel vault Obsidian, nella cartella `Publish/`. `scripts/publish.ps1` le valida, le copia in `content/`, fa commit e push; una GitHub Action costruisce il sito.

## Setup (una volta)

1. PowerShell 7, Node >= 22, git.
2. `copy scripts\publish.config.example.json scripts\publish.config.json` e imposta `publishDir` sul percorso di `Publish/`.
3. Su GitHub: Settings → Pages → Source "GitHub Actions".
4. In ogni nota da pubblicare: `title`, `description`, `image` (relativo a `Publish/`); opzionali `date: yyyy-MM-dd`, `pinned: true` (max 4) e `tags` (lista o testo separato da virgole; maiuscole indifferenti). Un tag presente in almeno 3 note diventa una card nella home, e quelle note escono da "Posts". Le card aperte restano aperte tornando alla home (pulsante Home, "indietro" o ricaricamento) finché la scheda del browser è aperta. Un valore che contiene `: ` (o finisce con `:`) va tra virgolette, altrimenti la build di Quartz fallisce: lo script lo segnala come errore.

## Pubblicare

```powershell
pwsh scripts/publish.ps1 -WhatIf   # anteprima, non tocca nulla
pwsh scripts/publish.ps1           # valida, copia, commit, push
```

Il repo locale deve stare sul branch `main` (lo script rifiuta altrimenti: è quello che fa partire il deploy). Se un push fallisce, rilancia lo script: reinvia i commit rimasti indietro.

La home (`content/index.md`) appartiene al repo e non viene toccata dal mirror. Test: `Invoke-Pester tests/` (Pester >= 5.5). Anteprima locale: `npx quartz build --serve -d content`.

## Logo e immagini del sito

Il logo (la rete di sei nodi), la favicon, le icone per telefono e la cover delle anteprime social nascono da un solo disegno, in `scripts/brand-assets.mjs`. Per rigenerare tutto in `quartz/static`: `node scripts/brand-assets.mjs`. Il manifest è `quartz/static/site.webmanifest` e va tenuto allineato a nome e descrizione in `quartz/site-info.ts` (lo verifica `npm test`). Le pagine senza cover propria usano `og-image.png` come anteprima. WhatsApp e gli altri social tengono in memoria le anteprime già viste: un link già condiviso può mostrare la vecchia immagine per giorni.
