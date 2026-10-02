// Scoped to the garden frame. Widths: 56rem column, 42rem text measure.
export const GARDEN_CSS = `
.page[data-frame="garden"] {
  --garden-wide: 56rem;
  --garden-measure: 42rem;
  --garden-gutter: clamp(16px, 4vw, 32px);
}

.page[data-frame="garden"] > #quartz-body {
  display: block;
  width: min(100% - 2 * var(--garden-gutter), var(--garden-wide));
  margin: 0 auto;
  padding: 0 0 3rem;
}

/* Top bar */
.page[data-frame="garden"] nav[data-role="site-nav"] {
  padding: 1.5rem 0;
  margin-bottom: clamp(1.5rem, 5vw, 3.5rem);
  font-family: var(--headerFont);
  font-weight: 700;
  letter-spacing: -0.01em;
}
.page[data-frame="garden"] nav[data-role="site-nav"] a {
  color: var(--dark);
  text-decoration: none;
}
.page[data-frame="garden"] nav[data-role="site-nav"] a:hover {
  color: var(--secondary);
}

/* Article header */
.page[data-frame="garden"] header[data-role="article-header"] h1 {
  margin: 0 0 1rem;
  font-family: var(--headerFont);
  font-size: clamp(2.1rem, 5.5vw, 3.4rem);
  line-height: 1.08;
  letter-spacing: -0.025em;
  font-weight: 700;
  text-wrap: balance;
}
.page[data-frame="garden"] [data-role="summary"] {
  margin: 0 0 1rem;
  max-width: var(--garden-measure);
  font-size: clamp(1.1rem, 2.2vw, 1.35rem);
  line-height: 1.5;
  color: var(--darkgray);
}
.page[data-frame="garden"] header[data-role="article-header"] time {
  font-family: var(--headerFont);
  font-size: 0.9rem;
  color: var(--secondary);
}
.page[data-frame="garden"] img[data-role="cover"] {
  display: block;
  width: 100%;
  height: auto;
  margin: 2rem 0 2.75rem;
  border-radius: 4px;
}

/* Article body */
.page[data-frame="garden"] .markdown-rendered {
  font-size: clamp(1.0625rem, 0.9rem + 0.5vw, 1.1875rem);
  line-height: 1.7;
}
.page[data-frame="garden"] .markdown-rendered > :where(p, ul, ol, h2, h3, h4, blockquote, hr, details) {
  max-width: var(--garden-measure);
}
.page[data-frame="garden"] .markdown-rendered :where(p, li, blockquote) {
  line-height: 1.7;
}
.page[data-frame="garden"] .markdown-rendered p {
  margin: 0 0 1.25em;
}
.page[data-frame="garden"] .markdown-rendered h2 {
  margin: 3.25rem 0 1rem;
  font-size: clamp(1.45rem, 2.4vw, 1.75rem);
  line-height: 1.2;
  letter-spacing: -0.015em;
}
.page[data-frame="garden"] .markdown-rendered h3 {
  margin: 2.75rem 0 0.75rem;
  font-size: clamp(1.25rem, 2.2vw, 1.45rem);
  line-height: 1.3;
}
.page[data-frame="garden"] .markdown-rendered :where(ul, ol) {
  margin: 0 0 1.25em;
  padding-left: 1.4em;
}
.page[data-frame="garden"] .markdown-rendered li + li {
  margin-top: 0.4em;
}
.page[data-frame="garden"] .markdown-rendered blockquote {
  margin: 1.75rem 0;
  padding: 0 0 0 1.25rem;
  border-left: 2px solid var(--secondary);
  color: var(--darkgray);
}
.page[data-frame="garden"] .markdown-rendered hr {
  margin: 2.5rem 0;
  border: 0;
  border-top: 1px solid var(--lightgray);
}
.page[data-frame="garden"] .markdown-rendered :where(pre, table, figure, img) {
  margin: 1.75rem 0;
}
.page[data-frame="garden"] .markdown-rendered a {
  color: var(--secondary);
  background: none;
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 0.2em;
}
.page[data-frame="garden"] .markdown-rendered a:hover {
  text-decoration-thickness: 2px;
}

/* Footer with the thread divider */
.page[data-frame="garden"] footer[data-role="site-footer"] {
  margin-top: 4rem;
  color: var(--darkgray);
  font-size: 0.875rem;
}
.page[data-frame="garden"] footer[data-role="site-footer"] svg {
  display: block;
  width: 7.5rem;
  height: auto;
  margin-bottom: 1rem;
  color: var(--secondary);
}
.page[data-frame="garden"] footer[data-role="site-footer"] p {
  margin: 0;
}
.page[data-frame="garden"] footer[data-role="site-footer"] a {
  color: inherit;
  font-weight: inherit;
}

/* Home */
.page[data-frame="garden"] .garden-home header[data-role="site-header"] {
  padding: clamp(2rem, 8vw, 5rem) 0 clamp(1.5rem, 5vw, 3rem);
}
.page[data-frame="garden"] .garden-home header[data-role="site-header"] h1 {
  margin: 0 0 0.75rem;
  font-family: var(--headerFont);
  font-size: clamp(2.6rem, 8vw, 4.5rem);
  line-height: 1;
  letter-spacing: -0.03em;
}
.page[data-frame="garden"] [data-role="tagline"] {
  margin: 0;
  max-width: var(--garden-measure);
  font-size: clamp(1.1rem, 2.2vw, 1.3rem);
  line-height: 1.5;
  color: var(--darkgray);
}
.page[data-frame="garden"] .garden-home section {
  margin-top: clamp(2.5rem, 7vw, 4rem);
}
.page[data-frame="garden"] .garden-home section > h2 {
  margin: 0 0 1.25rem;
  font-family: var(--headerFont);
  font-size: 1rem;
  font-weight: 600;
  color: var(--darkgray);
}
.page[data-frame="garden"] .garden-home ul {
  list-style: none;
  margin: 0;
  padding: 0;
}
.page[data-frame="garden"] .garden-home [data-role="note"] time {
  display: block;
  font-family: var(--headerFont);
  font-size: 0.85rem;
  color: var(--secondary);
}
.page[data-frame="garden"] .garden-home [data-role="note-title"] {
  display: block;
  font-family: var(--headerFont);
  font-size: clamp(1.2rem, 2.4vw, 1.45rem);
  font-weight: 700;
  line-height: 1.25;
  letter-spacing: -0.01em;
  color: var(--dark);
  text-decoration: none;
  background: none;
}
.page[data-frame="garden"] .garden-home [data-role="note-title"]:hover {
  color: var(--secondary);
}
.page[data-frame="garden"] .garden-home [data-role="note"] [data-role="summary"] {
  margin: 0.4rem 0 0;
  font-size: 1rem;
  line-height: 1.55;
}

/* Pinned cards */
.page[data-frame="garden"] .garden-home [data-section="pinned"] ul {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 24rem), 1fr));
  gap: 2.25rem 1.75rem;
}
.page[data-frame="garden"] img[data-role="card-cover"] {
  display: block;
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  margin-bottom: 0.9rem;
  border-radius: 4px;
}

/* Chronological list */
.page[data-frame="garden"] .garden-home [data-section="list"] [data-role="note"] {
  padding: 1.25rem 0;
  border-top: 1px solid var(--lightgray);
}
@media (min-width: 640px) {
  .page[data-frame="garden"] .garden-home [data-section="list"] [data-role="note"] {
    display: grid;
    grid-template-columns: 9rem 1fr;
    column-gap: 1.5rem;
  }
  .page[data-frame="garden"] .garden-home [data-section="list"] [data-role="note"] time {
    grid-row: 1 / span 2;
    padding-top: 0.35rem;
  }
  .page[data-frame="garden"] .garden-home [data-section="list"] [data-role="note"] > :not(time) {
    grid-column: 2;
  }
}
`
