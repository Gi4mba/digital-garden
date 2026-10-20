// Generates every brand image from one drawing: the "network" mark on the dark tile.
// Run: node scripts/brand-assets.mjs   (writes into quartz/static)
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import sharp from "sharp"

const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "quartz", "static")
const BG = "#0F1414"
const INK = "#6DBFC6"

// The mark, on a 64 grid: six nodes joined by thin hyphae.
const MARK = `<g fill="none" stroke="${INK}" stroke-width="3.5" stroke-linecap="round"><path d="M16 44L31 30L49 40"/><path d="M31 30L42 14"/><path d="M31 30L20 15"/><path d="M49 40L52 52"/></g><g fill="${INK}"><circle cx="16" cy="44" r="5.5"/><circle cx="31" cy="30" r="6.5"/><circle cx="49" cy="40" r="5.5"/><circle cx="42" cy="14" r="5"/><circle cx="20" cy="15" r="5"/><circle cx="52" cy="52" r="4.5"/></g>`

const scaled = (k) => `<g transform="translate(32 32) scale(${k}) translate(-32 -32)">${MARK}</g>`
const svg = (body, size = 64, extra = "") =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 64 64"${extra}>${body}</svg>`

const tile = svg(`<rect width="64" height="64" rx="14" fill="${BG}"/>${MARK}`)
const square = (k) => svg(`<rect width="64" height="64" fill="${BG}"/>${scaled(k)}`)

function mulberry32(seed) {
  let a = seed
  return () => {
    a |= 0
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

// The same seeded network as the home header, stretched over the cover.
function coverSvg() {
  const W = 1200
  const H = 630
  const COLS = 10
  const ROWS = 5
  const rand = mulberry32(7)
  const nodes = []
  for (let r = 0; r < ROWS; r++)
    for (let c = 0; c < COLS; c++)
      nodes.push({
        x: Math.round((c + 0.15 + rand() * 0.7) * (W / COLS)),
        y: Math.round((r + 0.15 + rand() * 0.7) * (H / ROWS)),
      })
  const seen = new Set()
  const edges = []
  nodes.forEach((n, i) => {
    nodes
      .map((m, j) => ({ j, d: (m.x - n.x) ** 2 + (m.y - n.y) ** 2 }))
      .filter((o) => o.j !== i)
      .sort((p, q) => p.d - q.d)
      .slice(0, 2)
      .forEach(({ j }) => {
        const key = i < j ? `${i}-${j}` : `${j}-${i}`
        if (!seen.has(key)) {
          seen.add(key)
          edges.push([n, nodes[j]])
        }
      })
  })
  const lines = edges
    .map(([a, b]) => `<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}"/>`)
    .join("")
  const dots = nodes.map((n) => `<circle cx="${n.x}" cy="${n.y}" r="3.5"/>`).join("")
  const T = 300
  const logo = `<g transform="translate(${(W - T) / 2} ${(H - T) / 2}) scale(${T / 64})"><rect width="64" height="64" rx="14" fill="${BG}" stroke="${INK}" stroke-opacity="0.5" stroke-width="0.6"/>${MARK}</g>`
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><rect width="${W}" height="${H}" fill="${BG}"/><g stroke="${INK}" stroke-opacity="0.38" stroke-width="1.6" stroke-linecap="round">${lines}</g><g fill="${INK}" fill-opacity="0.6">${dots}</g>${logo}</svg>`
}

const png = (source, size, name, opts = {}) =>
  sharp(Buffer.from(source), { density: 384 })
    .resize(size.w, size.h ?? size.w)
    .png({ compressionLevel: 9, palette: true, ...opts })
    .toFile(path.join(OUT, name))

fs.writeFileSync(path.join(OUT, "icon.svg"), tile)
await png(tile, { w: 512 }, "icon.png")
await png(tile, { w: 192 }, "icon-192.png")
await png(square(0.7), { w: 512 }, "icon-maskable-512.png")
await png(square(0.86), { w: 180 }, "apple-touch-icon.png")
await png(coverSvg(), { w: 1200, h: 630 }, "og-image.png")
console.log("brand assets written to", OUT)
