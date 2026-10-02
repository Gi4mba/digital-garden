import { siteInfo } from "../../../site-info"
import { PageFrameProps } from "../types"
import {
  MAX_PINNED,
  NoteInfo,
  compareNotes,
  coverSrc,
  formatNoteDate,
  hrefTo,
  listNotes,
} from "./notes"
import { Network } from "./Network"
import { SiteFooter } from "./SiteFooter"
import { FullSlug } from "../../../util/path"

function NoteItem({
  note,
  from,
  withCover,
  featured,
}: {
  note: NoteInfo
  from: FullSlug
  withCover: boolean
  featured?: boolean
}) {
  return (
    <li data-role="note" data-featured={featured ? "true" : undefined}>
      {withCover && note.image && (
        <img data-role="card-cover" src={coverSrc(from, note.image)} alt={note.title} />
      )}
      {note.date && <time dateTime={note.date}>{formatNoteDate(note.date)}</time>}
      <a data-role="note-title" href={hrefTo(from, note.slug)}>
        {note.title}
      </a>
      {note.description && <p data-role="summary">{note.description}</p>}
    </li>
  )
}

export function HomeView({ componentData }: PageFrameProps) {
  const from = componentData.fileData.slug!
  const notes = listNotes(componentData.allFiles)
  // The extra pinned notes beyond the cap fall back to the chronological list.
  const pinned = notes
    .filter((n) => n.pinned)
    .sort(compareNotes)
    .slice(0, MAX_PINNED)
  const rest = notes.filter((n) => !pinned.includes(n)).sort(compareNotes)

  return (
    <>
      <main class="garden-column garden-home">
        <header data-role="site-header">
          <Network />
          <h1>{siteInfo.name}</h1>
          <p data-role="tagline">{siteInfo.description}</p>
        </header>
        {pinned.length > 0 && (
          <section data-section="pinned">
            <h2>Featured</h2>
            <ul>
              {pinned.map((n, i) => (
                <NoteItem note={n} from={from} withCover featured={i === 0} />
              ))}
            </ul>
          </section>
        )}
        {rest.length > 0 && (
          <section data-section="list">
            <h2>Posts</h2>
            <ul>
              {rest.map((n) => (
                <NoteItem note={n} from={from} withCover={false} />
              ))}
            </ul>
          </section>
        )}
      </main>
      <SiteFooter />
    </>
  )
}
