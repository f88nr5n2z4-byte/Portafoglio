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
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function acceptedChanges(){return requests.filter(r=>r.status==='ACCETTATA'&&String(r.kind||'').toUpperCase()==='TURNO')}
function refreshAbsences(){
  const title=[...document.querySelectorAll('.list-card h3')].find(x=>x.textContent.trim()==='Ferie e assenze inserite');
  if(!title)return;
  const card=title.closest('.list-card');
  if(!card)return;
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
