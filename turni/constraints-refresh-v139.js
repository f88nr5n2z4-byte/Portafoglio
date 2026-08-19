(()=>{
'use strict';
const DRAFT='tm_v91_draft';
function validAdd(){const f=document.getElementById('v125From')?.value,t=document.getElementById('v125To')?.value||f;return !!f&&(!t||t>=f)}
function invalidate(){localStorage.removeItem(DRAFT);setTimeout(()=>{alert('Assenze aggiornate. La vecchia bozza è stata rimossa: genera di nuovo le 3 settimane per applicare le modifiche.');location.reload()},80)}
document.addEventListener('click',e=>{const add=e.target.closest?.('#v125Add');if(add&&validAdd()){invalidate();return}const del=e.target.closest?.('#v125AbsBody [data-del]');if(del)invalidate()});
function badge(){const b=document.querySelector('.v125head>span');if(b)b.textContent='v139'}
new MutationObserver(badge).observe(document.documentElement,{childList:true,subtree:true});if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',badge);else badge();
})();