(()=>{
'use strict';
const s=document.createElement('style');
s.textContent=`
html,body{overflow-x:hidden!important;overflow-y:auto!important;-webkit-overflow-scrolling:touch!important}
.v92timeline{touch-action:auto!important;overscroll-behavior:auto!important}
.v92scroll{width:100%!important;max-width:100%!important;overflow-x:auto!important;overflow-y:hidden!important;-webkit-overflow-scrolling:touch!important;touch-action:auto!important;overscroll-behavior:auto!important;margin-left:0!important}
.v92chart,.v92track,.v92row,.v92axis,.v92name{touch-action:auto!important}
@media(max-width:700px){.v92scroll{width:100%!important;max-width:100%!important}}
`;
document.head.appendChild(s);
function fix(){
 const sc=document.getElementById('v92Scroll');
 if(!sc||sc.dataset.iosScrollFixed==='1')return;
 sc.dataset.iosScrollFixed='1';
 sc.style.touchAction='auto';
 sc.addEventListener('touchstart',()=>{}, {passive:true});
 sc.addEventListener('touchmove',()=>{}, {passive:true});
}
let t;new MutationObserver(()=>{clearTimeout(t);t=setTimeout(fix,40)}).observe(document.body,{childList:true,subtree:true});
window.addEventListener('load',()=>setTimeout(fix,200));setTimeout(fix,300);
})();