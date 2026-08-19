(()=>{
'use strict';
function clean(){
 document.querySelectorAll('a,button,summary').forEach(el=>{
  const t=(el.textContent||'').trim().replace(/\s+/g,' ');
  if(/^visualizza\s+errori\b/i.test(t)||/^vedi\s+errori\b/i.test(t))el.remove();
 });
 document.querySelectorAll('.validation,.errors-panel,.error-summary').forEach(el=>el.remove());
}
new MutationObserver(clean).observe(document.documentElement,{childList:true,subtree:true});
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',clean);else clean();
setTimeout(clean,150);
})();