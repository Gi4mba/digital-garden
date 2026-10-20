// Remembers which tag cards are open for as long as the tab lives, so that clicking a note by
// mistake and coming back (Home button, browser back, reload) finds the cards as they were left.
// It runs right after the cards, before the first paint and before the browser restores the scroll
// position. Storage is optional: if it throws, the cards simply stay closed as before.
// While restoring, transitions are off; the timeout is a fallback for pages that never paint.
// No exit handler on purpose: it would keep the page out of the browser's instant back cache.
const SCRIPT = `(function(){
var sec=document.currentScript.parentNode,KEY='garden:open-tags';
var cards=[].slice.call(sec.querySelectorAll('details[data-role="tag-card"]'));
function name(d){return d.querySelector('[data-role="tag-name"]').textContent}
function read(){try{var v=JSON.parse(sessionStorage.getItem(KEY));return Array.isArray(v)?v:[]}catch(e){return[]}}
function write(){try{sessionStorage.setItem(KEY,JSON.stringify(cards.filter(function(d){return d.open}).map(name)))}catch(e){}}
var saved=read();
if(saved.length){sec.setAttribute('data-restoring','');
cards.forEach(function(d){if(saved.indexOf(name(d))>-1)d.open=true});
function done(){sec.removeAttribute('data-restoring')}
requestAnimationFrame(function(){requestAnimationFrame(done)});setTimeout(done,1000)}
sec.addEventListener('toggle',write,true)})()`

export function TagCardMemory() {
  return <script dangerouslySetInnerHTML={{ __html: SCRIPT }} />
}
