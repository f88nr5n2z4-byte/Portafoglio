(()=>{
'use strict';
const KEY='tm_v91_draft';
function bind(){
 const old=document.getElementById('v91Gen');
 if(!old||old.dataset.v113==='1')return;
 const b=old.cloneNode(true);
 b.classList.remove('v91gen');
 b.classList.add('v113gen');
 b.dataset.v113='1';
 b.textContent='Genera 3 settimane';
 old.replaceWith(b);
 b.onclick=e=>{
  e.preventDefault();e.stopPropagation();
  const start=document.getElementById('v91Start')?.value;
  if(!window.TM112?.generate){alert('Generatore v112 non caricato. Riapri la pagina e riprova.');return}
  b.disabled=true;b.textContent='Generazione…';
  requestAnimationFrame(()=>setTimeout(()=>{
   try{
    const draft=window.TM112.generate(start);
    const errors=window.TM112.validateSchedule(draft);
    if(errors.length){console.error('v113 test generation errors',errors);alert(`Generazione bloccata: ${errors.length} errori. Apri la console per i dettagli.`);b.disabled=false;b.textContent='Genera 3 settimane';return}
    localStorage.setItem(KEY,JSON.stringify(draft));
    location.reload();
   }catch(err){console.error(err);alert('Errore nella generazione: '+(err?.message||err));b.disabled=false;b.textContent='Genera 3 settimane'}
  },40));
 };
}
const css=document.createElement('style');css.textContent='.v113gen{background:#ffd100;color:#003d7c;border:0!important;font-weight:950}.v113gen:disabled{opacity:.65}';document.head.appendChild(css);
new MutationObserver(bind).observe(document.getElementById('app')||document.documentElement,{childList:true,subtree:true});
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bind);else bind();
setTimeout(bind,100);
})();