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
        <a href={`${pathToRoot(fileData.slug!)}/`}>
          <svg
            data-role="back-arrow"
            viewBox="0 0 16 16"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M13 8H3M7.5 3.5L3 8l4.5 4.5" />
          </svg>
          Home
        </a>
      </nav>
      <main class="garden-column">
        <header data-role="article-header">
          <h1>{title}</h1>
          {description && <p data-role="summary">{description}</p>}
          {date && <time dateTime={date}>{formatNoteDate(date)}</time>}
        </header>
        {image && <img data-role="cover" src={coverSrc(fileData.slug!, image)} alt="" />}
        <Content {...componentData} />
      </main>
      <SiteFooter />
    </>
  )
}
