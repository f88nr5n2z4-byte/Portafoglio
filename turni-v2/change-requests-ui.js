(()=>{
'use strict';
let requests=[];
const nativeFetch=window.fetch.bind(window);
window.fetch=async(...args)=>{
  const res=await nativeFetch(...args);
  try{
    const u=String(typeof args[0]==='string'?args[0]:args[0]?.url||'');
    if(u.includes('turni-clean-api')&&u.includes('action=my_requests')){
      const data=await res.clone().json();
      requests=Array.isArray(data?.requests)?data.requests:[];
      queueMicrotask(refresh);
    }
  }catch{}
  return res;
};
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot',"'":'&#39;'}[c]))}
function ymd(d){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`}
function currentMonday(){const d=new Date(),day=d.getDay()||7;d.setHours(12,0,0,0);d.setDate(d.getDate()-day+1);return ymd(d)}
function acceptedChanges(){const min=currentMonday();return requests.filter(r=>r.status==='ACCETTATA'&&String(r.kind||'').toUpperCase()==='TURNO'&&String(r.request_date||'')>=min)}
function hidePastRows(card){
  const min=currentMonday(),list=card?.querySelector('.absence-list');
  if(!list)return;
  [...list.children].forEach(row=>{
    const dates=String(row.textContent||'').match(/\b\d{4}-\d{2}-\d{2}\b/g)||[];
    if(dates.length&&dates.sort().at(-1)<min)row.remove();
  });
  if(!list.children.length&&!card.querySelector('.empty-mini')){
    const e=document.createElement('div');e.className='empty-mini';e.textContent='Nessuna ferie, assenza o richiesta per la settimana corrente e le successive.';card.appendChild(e);
  }
}
function refreshAbsences(){
  const title=[...document.querySelectorAll('.list-card h3')].find(x=>x.textContent.trim()==='Ferie e assenze inserite');
  if(!title)return;
  const card=title.closest('.list-card');
  if(!card)return;
  hidePastRows(card);
  let list=card.querySelector('.absence-list');
  const rows=acceptedChanges();
  if(!rows.length)return;
  if(!list){card.querySelector('.empty-mini')?.remove();list=document.createElement('div');list.className='absence-list';card.appendChild(list)}
  rows.forEach(r=>{
    if(list.querySelector(`[data-change-request="${CSS.escape(String(r.id))}"]`))return;
    const d=r.request_date||'';
    const row=document.createElement('div');
    row.dataset.changeRequest=String(r.id);
    row.innerHTML=`<span class="absence-icon">⇄</span><div><b>${esc(r.employee_name)}</b><small>CAMBIO TURNO · ${esc(d)} → ${esc(d)}${r.wanted_shift?` · turno richiesto: ${esc(r.wanted_shift)}`:''} · richiesta accettata</small></div><span></span>`;
    list.appendChild(row);
  });
  hidePastRows(card);
}
function refreshRequests(){
  document.querySelectorAll('.request-card-top small').forEach(el=>{
    const t=el.textContent.trim();
    if(/^TURNO\s*·/i.test(t))el.textContent=t.replace(/^TURNO/i,'CAMBIO TURNO');
  });
}
function refresh(){refreshAbsences();refreshRequests()}
new MutationObserver(()=>queueMicrotask(refresh)).observe(document.documentElement,{subtree:true,childList:true});
document.addEventListener('DOMContentLoaded',refresh);
})();
