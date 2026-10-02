import { siteInfo } from "../../../site-info"

// A thin branching thread, the one decorative mark of the garden.
function Thread() {
  return (
    <svg
      data-role="thread"
      viewBox="0 0 896 24"
      preserveAspectRatio="none"
      fill="none"
      stroke="currentColor"
      stroke-width="1"
      stroke-linecap="round"
      aria-hidden="true"
    >
      <path
        vector-effect="non-scaling-stroke"
        d="M0 14 C90 14 130 7 230 8 S400 15 520 13 S760 9 896 11"
      />
      <path vector-effect="non-scaling-stroke" d="M230 8 C250 4 275 3 300 2" />
      <path vector-effect="non-scaling-stroke" d="M520 13 C545 17 575 20 610 22" />
      <path vector-effect="non-scaling-stroke" d="M760 9 C775 5 795 3 820 2" />
    </svg>
  )
}

export function SiteFooter() {
  const host = new URL(siteInfo.homeUrl).host
  return (
    <footer data-role="site-footer">
      <Thread />
      <p>
        © {new Date().getFullYear()} {siteInfo.author} · <a href={siteInfo.homeUrl}>{host}</a>
      </p>
    </footer>
  )
}
