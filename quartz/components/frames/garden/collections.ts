import { MAX_PINNED, NoteInfo, compareNotes } from "./notes"

/** A tag becomes a card on the home once this many notes carry it. */
export const MIN_COLLECTION_SIZE = 3

export type TagCollection = { tag: string; notes: NoteInfo[] }

export type HomeSections = {
  pinned: NoteInfo[]
  collections: TagCollection[]
  rest: NoteInfo[]
}

/** Tags with at least MIN_COLLECTION_SIZE notes; most notes first, then by name. */
export function buildCollections(notes: NoteInfo[]): TagCollection[] {
  const byTag = new Map<string, NoteInfo[]>()
  for (const note of notes) {
    for (const tag of new Set(note.tags)) {
      byTag.set(tag, [...(byTag.get(tag) ?? []), note])
    }
  }
  return [...byTag]
    .filter(([, tagged]) => tagged.length >= MIN_COLLECTION_SIZE)
    .map(([tag, tagged]) => ({ tag, notes: [...tagged].sort(compareNotes) }))
    .sort((a, b) => b.notes.length - a.notes.length || a.tag.localeCompare(b.tag))
}

/**
 * Splits the home into its three blocks. A pinned note stays pinned even when it is in a
 * collection; notes in any collection leave the chronological list.
 */
export function splitHome(notes: NoteInfo[]): HomeSections {
  const pinned = notes
    .filter((n) => n.pinned)
    .sort(compareNotes)
    .slice(0, MAX_PINNED)
  const collections = buildCollections(notes)
  const carded = new Set(collections.flatMap((c) => c.notes))
  const rest = notes.filter((n) => !pinned.includes(n) && !carded.has(n)).sort(compareNotes)
  return { pinned, collections, rest }
}
