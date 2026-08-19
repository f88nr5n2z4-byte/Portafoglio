(()=>{
'use strict';
function clean(){
 const root=document.getElementById('app');
 if(!root)return;
 root.querySelectorAll('.v91check,.v91errors').forEach(el=>el.remove());
 root.querySelectorAll('.v91top b').forEach(el=>{if(/Generatore v95/i.test(el.textContent||''))el.textContent='Nuovi Turni';});
 root.querySelectorAll('.v91hero p').forEach(el=>{el.textContent='Generazione turni con il motore unificato attuale.';});
 const pub=root.querySelector('#v91Publish');if(pub)pub.disabled=false;
}
new MutationObserver(clean).observe(document.getElementById('app')||document.documentElement,{childList:true,subtree:true,attributes:true,attributeFilter:['disabled']});
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',clean);else clean();
setTimeout(clean,100);setTimeout(clean,400);
})();