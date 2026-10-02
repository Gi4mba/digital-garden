import { PageFrameProps } from "../types"
import { pathToRoot } from "../../../util/path"
import { coverSrc, formatNoteDate, noteDate } from "./notes"
import { ProgressThread } from "./ProgressThread"
import { SiteFooter } from "./SiteFooter"

export function ArticleView({ componentData, pageBody: Content }: PageFrameProps) {
  const { fileData } = componentData
  const fm = (fileData.frontmatter ?? {}) as Record<string, any>
  const title = fm.title ? String(fm.title) : ""
  const description = fm.description ? String(fm.description) : ""
  const image = fm.image ? String(fm.image) : undefined
  const date = noteDate(fm)

  return (
    <>
      <ProgressThread />
      <nav data-role="site-nav">
        <a href={`${pathToRoot(fileData.slug!)}/`}>Home</a>
      </nav>
      <main class="garden-column">
        <header data-role="article-header">
          <h1>{title}</h1>
          {description && <p data-role="summary">{description}</p>}
          {date && <time dateTime={date}>{formatNoteDate(date)}</time>}
        </header>
        {image && <img data-role="cover" src={coverSrc(fileData.slug!, image)} alt={title} />}
        <Content {...componentData} />
      </main>
      <SiteFooter />
    </>
  )
}
