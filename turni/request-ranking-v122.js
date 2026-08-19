(()=>{
'use strict';
const ordinal=n=>n===2?'Seconda richiesta':n===3?'Terza richiesta':n===4?'Quarta richiesta':n===5?'Quinta richiesta':`${n}ª richiesta`;
const structured=x=>/Giorno:\s*[^\n]+.*?Turno richiesto:\s*[^\n]+/s.test(String(x.message||''));
async function run(){
 try{
  const r=await api('list_requests'),list=r.requests||[],counts={},rank={};
  list.filter(structured).slice().sort((a,b)=>new Date(a.created_at||0)-new Date(b.created_at||0)).forEach(x=>{const k=x.employee||'';counts[k]=(counts[k]||0)+1;rank[x.id]=counts[k]});
  const scan=()=>document.querySelectorAll('[data-normal]').forEach(b=>{const n=rank[+b.dataset.normal]||1;if(n<2)return;const card=b.closest('.request-item');if(!card||card.querySelector('.req-rank-v122'))return;const meta=card.querySelector('.request-meta');if(!meta)return;const s=document.createElement('span');s.className='req-rank-v122';s.textContent=ordinal(n);meta.appendChild(s)});
  scan();new MutationObserver(scan).observe(document.getElementById('inbox')||document.body,{childList:true,subtree:true});
 }catch(e){console.warn('request ranking v122',e)}
}
const style=document.createElement('style');style.textContent='.req-rank-v122{display:inline-block;margin-left:6px;padding:3px 6px;border-radius:999px;background:#ffd500;color:#003d7c;font-size:9px;font-weight:950}';document.head.appendChild(style);
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run);else run();
})();