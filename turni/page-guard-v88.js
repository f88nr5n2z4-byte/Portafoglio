(()=>{
'use strict';
function show(msg){const app=document.getElementById('app');if(!app||app.children.length)return;app.innerHTML=`<div class="error" style="margin:20px"><b>Errore pagina</b><br>${String(msg||'Errore sconosciuto').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]))}</div>`}
window.addEventListener('error',e=>setTimeout(()=>show(e.message),0));
window.addEventListener('unhandledrejection',e=>setTimeout(()=>show(e.reason?.message||e.reason),0));
setTimeout(()=>{const app=document.getElementById('app');if(app&&!app.children.length)show('La pagina non ha completato il caricamento. Riprova dalla Home.')},8000);
})();