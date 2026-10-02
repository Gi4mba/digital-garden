import { QuartzPluginData } from "../../../plugins/vfile"
import {
  FilePath,
  FullSlug,
  joinSegments,
  pathToRoot,
  resolveRelative,
  slugifyFilePath,
} from "../../../util/path"

export const MAX_PINNED = 4

export type NoteInfo = {
  slug: FullSlug
  title: string
  description: string
  image?: string
  date?: string
  pinned: boolean
}

/** Frontmatter `date` as yyyy-MM-dd, or undefined when missing/invalid. */
export function noteDate(fm: Record<string, any> | undefined): string | undefined {
  const raw = fm?.date
  if (raw instanceof Date && !isNaN(raw.getTime())) return raw.toISOString().slice(0, 10)
  if (typeof raw === "string" && /^\d{4}-\d{2}-\d{2}$/.test(raw.trim())) return raw.trim()
  return undefined
}

export function isPinned(fm: Record<string, any> | undefined): boolean {
  return fm?.pinned === true || String(fm?.pinned).toLowerCase() === "true"
}

/** URL of the cover image relative to the page, as emitted by Quartz (slugified, then encoded). */
export function coverSrc(slug: FullSlug, image: string): string {
  return encodeURI(joinSegments(pathToRoot(slug), slugifyFilePath(image as FilePath)))
}

export function hrefTo(from: FullSlug, to: FullSlug): string {
  return encodeURI(resolveRelative(from, to))
}

export function formatNoteDate(date: string): string {
  return new Date(`${date}T00:00:00Z`).toLocaleDateString("it-IT", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  })
}

export function listNotes(allFiles: QuartzPluginData[]): NoteInfo[] {
  const notes: NoteInfo[] = []
  for (const file of allFiles) {
    const fm = file.frontmatter as Record<string, any> | undefined
    if (!file.slug || file.slug === "index" || file.slug === "404" || !fm?.title) continue
    notes.push({
      slug: file.slug,
      title: String(fm.title),
      description: fm.description ? String(fm.description) : "",
      image: fm.image ? String(fm.image) : undefined,
      date: noteDate(fm),
      pinned: isPinned(fm),
    })
  }
  return notes
}

/** Newest first; notes without a date go last; ties broken by title. */
export function compareNotes(a: NoteInfo, b: NoteInfo): number {
  if (a.date && b.date && a.date !== b.date) return a.date < b.date ? 1 : -1
  if (!a.date !== !b.date) return a.date ? -1 : 1
  return a.title.localeCompare(b.title, "it")
}
