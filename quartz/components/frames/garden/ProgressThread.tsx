// A thread that grows along the top edge while the article is read; each section heading
// sprouts a small branch once it has been reached. Pure decoration: hidden from assistive tech.
const SCRIPT = `(function(){
var bar=document.querySelector('[data-role="progress"]');if(!bar)return;
var main=bar.querySelector('path[data-main]'),g=bar.querySelector('g'),NS='http://www.w3.org/2000/svg';
var branches=[];
function max(){return Math.max(1,document.documentElement.scrollHeight-window.innerHeight)}
function layout(){var heads=[].slice.call(document.querySelectorAll('.markdown-rendered h2,.markdown-rendered h3'));g.textContent='';branches=[];var m=max();
heads.forEach(function(h,i){var top=h.getBoundingClientRect().top+window.scrollY;
var f=Math.min(1,Math.max(0.02,(top-window.innerHeight*0.5)/m));
var x=Math.round(f*1000),up=i%2===0,p=document.createElementNS(NS,'path');
p.setAttribute('d','M'+x+' 6 C'+(x+8)+' 6 '+(x+12)+(up?' 2 ':' 10 ')+(x+22)+(up?' 1':' 11'));
p.setAttribute('vector-effect','non-scaling-stroke');p.style.opacity='0';g.appendChild(p);branches.push({f:f,el:p})});
update()}
function update(){var p=Math.min(1,Math.max(0,window.scrollY/max()));
main.style.strokeDashoffset=String(1-p);
branches.forEach(function(b){b.el.style.opacity=p>=b.f?'1':'0'})}
window.addEventListener('scroll',update,{passive:true});window.addEventListener('resize',layout);
window.addEventListener('load',layout);layout()})()`

export function ProgressThread() {
  return (
    <>
      <div data-role="progress" aria-hidden="true">
        <svg
          viewBox="0 0 1000 12"
          preserveAspectRatio="none"
          fill="none"
          stroke="currentColor"
          stroke-width="1.5"
          stroke-linecap="round"
        >
          <path
            data-main
            d="M0 6 C200 5 300 7 500 6 S800 5 1000 6"
            pathLength="1"
            stroke-dasharray="1"
            stroke-dashoffset="1"
            stroke-linecap="butt"
          />
          <g />
        </svg>
      </div>
      <script dangerouslySetInnerHTML={{ __html: SCRIPT }} />
    </>
  )
}
