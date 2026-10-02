import { siteInfo } from "../../../site-info"

// A thin branching thread, the one decorative mark of the garden.
function Thread() {
  return (
    <svg
      data-role="thread"
      viewBox="0 0 120 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1"
      stroke-linecap="round"
      aria-hidden="true"
    >
      <path d="M0 14 C20 14 28 8 44 8 S70 14 84 14 S104 10 120 10" />
      <path d="M44 8 C50 4 56 3 64 2" />
      <path d="M84 14 C90 18 98 20 106 22" />
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
