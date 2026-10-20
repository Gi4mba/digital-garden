import test, { describe } from "node:test"
import assert from "node:assert"
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import sharp from "sharp"
import { siteInfo } from "./site-info"

const STATIC = path.join(path.dirname(fileURLToPath(import.meta.url)), "static")
const read = (name: string) => fs.readFileSync(path.join(STATIC, name))
const size = async (name: string) => {
  const { width, height } = await sharp(read(name)).metadata()
  return `${width}x${height}`
}

type Icon = { src: string; sizes: string; type: string; purpose?: string }
const manifest = () => JSON.parse(read("site.webmanifest").toString("utf8"))

describe("web app manifest", () => {
  test("describes the site with the same name and description as the pages", () => {
    const m = manifest()
    assert.strictEqual(m.name, siteInfo.name)
    assert.strictEqual(m.short_name, siteInfo.name)
    assert.strictEqual(m.description, siteInfo.description)
    assert.strictEqual(m.lang, "en")
  })

  test("opens the site root from the static folder, as an app", () => {
    const m = manifest()
    assert.strictEqual(m.start_url, "../")
    assert.strictEqual(m.scope, "../")
    assert.strictEqual(m.display, "standalone")
  })

  test("uses the dark colours of the logo and the site theme", () => {
    const m = manifest()
    assert.strictEqual(m.background_color, "#0F1414")
    assert.strictEqual(m.theme_color, "#0F1414")
  })

  test("lists icons that exist with the sizes they declare", async () => {
    const icons: Icon[] = manifest().icons
    assert.ok(icons.length >= 3)
    for (const icon of icons) {
      assert.strictEqual(icon.type, "image/png")
      assert.strictEqual(await size(icon.src), icon.sizes, icon.src)
    }
  })

  test("has plain 192 and 512 icons and a maskable 512 one", () => {
    const icons: Icon[] = manifest().icons
    const plain = icons.filter((i) => !i.purpose || i.purpose === "any").map((i) => i.sizes)
    assert.deepStrictEqual([...plain].sort(), ["192x192", "512x512"])
    const maskable = icons.filter((i) => i.purpose === "maskable")
    assert.deepStrictEqual(
      maskable.map((i) => i.sizes),
      ["512x512"],
    )
  })
})

describe("brand images", () => {
  test("the favicon source is a light file, not the old 2000px artwork", async () => {
    assert.strictEqual(await size("icon.png"), "512x512")
    assert.ok(read("icon.png").length < 100_000)
  })

  test("the vector icon is the 64 grid tile in the site colours", () => {
    const svg = read("icon.svg").toString("utf8")
    assert.match(svg, /viewBox="0 0 64 64"/)
    assert.match(svg, /#0F1414/)
    assert.match(svg, /#6DBFC6/)
  })

  test("the iPhone icon is 180px", async () => {
    assert.strictEqual(await size("apple-touch-icon.png"), "180x180")
  })

  test("the font used for the name on the cover ships with its licence", () => {
    const fonts = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "scripts", "fonts")
    assert.ok(fs.statSync(path.join(fonts, "SchibstedGrotesk[wght].ttf")).size > 100_000)
    assert.match(fs.readFileSync(path.join(fonts, "OFL.txt"), "utf8"), /SIL Open Font License/)
  })

  test("the social cover is 1200x630 and light", async () => {
    assert.strictEqual(await size("og-image.png"), "1200x630")
    assert.ok(read("og-image.png").length < 300_000)
  })
})
