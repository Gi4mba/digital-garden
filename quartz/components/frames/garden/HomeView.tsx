import { siteInfo } from "../../../site-info"
import { PageFrameProps } from "../types"
import { NoteInfo, coverSrc, formatNoteDate, hrefTo, listNotes } from "./notes"
import { TagCollection, splitHome } from "./collections"
import { Network } from "./Network"
import { SiteFooter } from "./SiteFooter"
import { TagCardMemory } from "./TagCardMemory"
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
        // Decorative: the title right below already names the note.
        <img data-role="card-cover" src={coverSrc(from, note.image)} alt="" />
      )}
      {note.date && <time dateTime={note.date}>{formatNoteDate(note.date)}</time>}
      <a data-role="note-title" href={hrefTo(from, note.slug)}>
        {note.title}
      </a>
      {note.description && <p data-role="summary">{note.description}</p>}
    </li>
  )
}

/** A closed native disclosure: independent drawers, keyboard and no-script support for free. */
function TagCard({ collection, from }: { collection: TagCollection; from: FullSlug }) {
  return (
    <details data-role="tag-card">
      <summary>
        <span data-role="tag-name">{collection.tag}</span>
        <span data-role="tag-count">{`(${collection.notes.length})`}</span>
      </summary>
      <ul>
        {collection.notes.map((n) => (
          <NoteItem note={n} from={from} withCover={false} />
        ))}
      </ul>
    </details>
  )
}

export function HomeView({ componentData }: PageFrameProps) {
  const from = componentData.fileData.slug!
  const { pinned, collections, rest } = splitHome(listNotes(componentData.allFiles))

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
        {collections.length > 0 && (
          <section data-section="tags">
            <h2>Tags</h2>
            <ul>
              {collections.map((c) => (
                <li>
                  <TagCard collection={c} from={from} />
                </li>
              ))}
            </ul>
            <TagCardMemory />
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
