export const GARDEN_CSS = `
.page[data-frame="garden"] > #quartz-body {
  display: block;
  max-width: 70ch;
  margin: 0 auto;
  padding: 3rem 16px 2rem;
}
.page[data-frame="garden"] header[data-role="article-header"] h1 {
  margin: 0 0 0.5rem;
  font-family: var(--headerFont);
  line-height: 1.15;
}
.page[data-frame="garden"] [data-role="summary"] {
  margin: 0 0 0.5rem;
  font-size: 1.15rem;
  color: var(--darkgray);
}
.page[data-frame="garden"] header[data-role="article-header"] time {
  color: var(--gray);
  font-size: 0.9rem;
}
.page[data-frame="garden"] img[data-role="cover"] {
  display: block;
  width: 100%;
  height: auto;
  margin: 1.5rem 0;
  border-radius: 6px;
}
.page[data-frame="garden"] footer[data-role="site-footer"] {
  margin-top: 4rem;
  padding-top: 1rem;
  border-top: 1px solid var(--lightgray);
  color: var(--gray);
  font-size: 0.9rem;
}
`
