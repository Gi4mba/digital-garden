import { siteInfo } from "../../../site-info"

export function SiteFooter() {
  const host = new URL(siteInfo.homeUrl).host
  return (
    <footer data-role="site-footer">
      <p>
        © {new Date().getFullYear()} {siteInfo.author} · <a href={siteInfo.homeUrl}>{host}</a>
      </p>
    </footer>
  )
}
