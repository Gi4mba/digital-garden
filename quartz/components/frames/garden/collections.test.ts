import test, { describe } from "node:test"
import assert from "node:assert"
import { FullSlug } from "../../../util/path"
import { NoteInfo, noteTags } from "./notes"
import { buildCollections, splitHome } from "./collections"

function note(
  title: string,
  tags: string[],
  extra: { date?: string; pinned?: boolean } = {},
): NoteInfo {
  return {
    slug: title.toLowerCase().replace(/\s+/g, "-") as FullSlug,
    title,
    description: "",
    date: extra.date,
    pinned: extra.pinned ?? false,
    tags,
  }
}

const titles = (notes: NoteInfo[]) => notes.map((n) => n.title)

describe("noteTags", () => {
  test("normalizes case, spaces and duplicates", () => {
    assert.deepStrictEqual(noteTags({ tags: ["Mesh", "mesh", " Smart Contracts "] }), [
      "mesh",
      "smart-contracts",
    ])
    assert.deepStrictEqual(noteTags({ tags: "Mesh, rust" }), ["mesh", "rust"])
    assert.deepStrictEqual(noteTags({ tags: null }), [])
    assert.deepStrictEqual(noteTags(undefined), [])
  })
})

describe("buildCollections", () => {
  test("a tag needs at least 3 notes", () => {
    const two = [note("A", ["mesh"]), note("B", ["mesh"])]
    assert.deepStrictEqual(buildCollections(two), [])
    const three = [...two, note("C", ["mesh"])]
    assert.deepStrictEqual(
      buildCollections(three).map((c) => [c.tag, c.notes.length]),
      [["mesh", 3]],
    )
  })

  test("most notes first, then alphabetical; notes newest first", () => {
    const notes = [
      note("R1", ["rust"], { date: "2026-01-01" }),
      note("R2", ["rust"], { date: "2026-03-01" }),
      note("R3", ["rust"], { date: "2026-02-01" }),
      note("G1", ["go"], { date: "2026-01-01" }),
      note("G2", ["go"], { date: "2026-02-01" }),
      note("G3", ["go"]),
      note("M1", ["mesh"], { date: "2026-01-01" }),
      note("M2", ["mesh"], { date: "2026-04-01" }),
      note("M3", ["mesh"], { date: "2026-02-01" }),
      note("M4", ["mesh"], { date: "2026-03-01" }),
    ]
    const collections = buildCollections(notes)
    assert.deepStrictEqual(
      collections.map((c) => c.tag),
      ["mesh", "go", "rust"],
    )
    assert.deepStrictEqual(titles(collections[0].notes), ["M2", "M4", "M3", "M1"])
    assert.deepStrictEqual(titles(collections[1].notes), ["G2", "G1", "G3"])
    assert.deepStrictEqual(titles(collections[2].notes), ["R2", "R3", "R1"])
  })

  test("a note with two tags above the threshold is in both collections", () => {
    const notes = [
      note("Both", ["mesh", "rust"]),
      note("M2", ["mesh"]),
      note("M3", ["mesh"]),
      note("R2", ["rust"]),
      note("R3", ["rust"]),
    ]
    const byTag = Object.fromEntries(buildCollections(notes).map((c) => [c.tag, titles(c.notes)]))
    assert.ok(byTag.mesh.includes("Both"))
    assert.ok(byTag.rust.includes("Both"))
  })
})

describe("splitHome", () => {
  test("keeps pinned notes pinned, removes carded notes from rest", () => {
    const notes = [
      note("Pinned Mesh", ["mesh"], { date: "2026-05-01", pinned: true }),
      note("Mesh A", ["mesh"], { date: "2026-04-01" }),
      note("Mesh B", ["mesh"], { date: "2026-03-01" }),
      note("Rust A", ["rust"], { date: "2026-02-01" }),
      note("Rust B", ["rust"], { date: "2026-01-01" }),
      note("Untagged", []),
      note("P1", [], { date: "2026-06-01", pinned: true }),
      note("P2", [], { date: "2026-07-01", pinned: true }),
      note("P3", [], { date: "2026-08-01", pinned: true }),
      note("Fifth Pin Mesh", ["mesh"], { date: "2025-01-01", pinned: true }),
    ]
    const { pinned, collections, rest } = splitHome(notes)
    assert.deepStrictEqual(titles(pinned), ["P3", "P2", "P1", "Pinned Mesh"])
    assert.deepStrictEqual(
      collections.map((c) => [c.tag, titles(c.notes)]),
      [["mesh", ["Pinned Mesh", "Mesh A", "Mesh B", "Fifth Pin Mesh"]]],
    )
    assert.deepStrictEqual(titles(rest), ["Rust A", "Rust B", "Untagged"])
  })
})
