import { PageFrame, PageFrameProps } from "../types"
import { ArticleView } from "./ArticleView"
import { GARDEN_CSS } from "./garden-css"

// Follows the OS light/dark preference; there is no manual toggle by design.
const THEME_SCRIPT = `(function(){var d=document.documentElement,m=window.matchMedia("(prefers-color-scheme: dark)");function s(){d.setAttribute("saved-theme",m.matches?"dark":"light")}s();m.addEventListener("change",s)})()`

/**
 * Single frame for the whole garden: Quartz picks frames per page type, and the
 * home page is a regular content page, so the frame renders the right view itself.
 */
export const GardenFrame: PageFrame = {
  name: "garden",
  css: GARDEN_CSS,
  render(props: PageFrameProps) {
    return (
      <>
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
        <ArticleView {...props} />
      </>
    )
  },
}
