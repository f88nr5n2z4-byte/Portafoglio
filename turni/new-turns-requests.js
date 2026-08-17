(()=>{
 const STORAGE='tm_planner_applied_requests';
 const originalDraw=draw, originalRepair=repair, originalPublish=publish;
 function wk(){return draft?.dates?.[0]||'next'}
 function loadApplied(){try{const all=JSON.parse(localStorage.getItem(STORAGE)||'{}');return Array.isArray(all[wk()])?all[wk()]:[]}catch{return[]}}
 function saveApplied(ids){let all={};try{all=JSON.parse(localStorage.getItem(STORAGE)||'{}')||{}}catch{}all[wk()]=ids;localStorage.setItem(STORAGE,JSON.stringify(all))}
 function parseReq(r){
  const m=String(r.message||'');
  if(!/RICHIESTA (CAMBIO TURNO|FERIE|PERMESSO|RIPOSO)/.test(m))return null;
  const dateLabel=(m.match(/Giorno:\s*([^\n]+)/)||[])[1]?.trim();
  let wanted=(m.match(/Turno richiesto:\s*([^\n]+)/)||[])[1]?.trim();
  if(!wanted){if(/RICHIESTA RIPOSO/.test(m))wanted='RIPOSO';else if(/RICHIESTA FERIE/.test(m))wanted='FERIE';else if(/RICHIESTA PERMESSO/.test(m))wanted='PERMESSO'}
  if(!dateLabel||!wanted)return null;
  return{r,dateLabel,wanted};
 }
 function relevant(){if(!draft)return[];return (requests||[]).map(parseReq).filter(Boolean).map(x=>({...x,di:draft.dates.findIndex(d=>fmtDate(d)===x.dateLabel)})).filter(x=>x.di>=0&&draft.schedule[x.r.employee]&&x.r.status!=='RIFIUTATA')}
 function applyStored(w){const ids=new Set(loadApplied());for(const x of relevant()){if(x.r.status==='ACCETTATA'||ids.has(Number(x.r.id))){w.schedule[x.r.employee][x.di]=x.wanted;locked.add(`${x.r.employee}|${x.di}`)}}return w}
 repair=function(w){applyStored(w);const out=originalRepair(w);applyStored(out);return out}
 function rerun(){if(!draft)return;applyStored(draft);repair(draft);draw([])}
 function mount(){
  if(!draft)return;const main=document.querySelector('.nt');if(!main)return;document.getElementById('plannerRequests')?.remove();
  const rel=relevant(),applied=new Set(loadApplied());
  const card=document.createElement('section');card.className='card planner-requests';card.id='plannerRequests';
  card.innerHTML=`<div class="pr-head"><div><h3>Richieste per questa settimana</h3><p>Applica qui riposi, ferie, permessi o turni richiesti prima di pubblicare.</p></div><span class="pr-count">${rel.length}</span></div>${rel.length?`<div class="pr-list">${rel.map(x=>{const accepted=x.r.status==='ACCETTATA',on=accepted||applied.has(Number(x.r.id));return `<div class="pr-item ${on?'applied':''}"><div class="pr-info"><b>${esc(x.r.employee)}</b><span>${esc(x.dateLabel)}</span><strong>${esc(x.wanted)}</strong><small>${accepted?'Già accettata':on?'Applicata alla bozza':'Da valutare'}</small></div>${accepted?`<span class="pr-ok">✓ Applicata</span>`:on?`<button type="button" class="pr-remove" data-remove-req="${x.r.id}">Rimuovi</button>`:`<button type="button" class="pr-apply" data-apply-req="${x.r.id}">Applica</button>`}</div>`}).join('')}</div>`:`<div class="pr-empty">Nessuna richiesta relativa alla settimana che stai creando.</div>`}`;
  const control=[...main.querySelectorAll('.card')].find(x=>x.querySelector('h3')?.textContent?.includes('Controllo regole'));
  if(control)control.insertAdjacentElement('beforebegin',card);else main.prepend(card);
  card.querySelectorAll('[data-apply-req]').forEach(b=>b.onclick=()=>{const id=Number(b.dataset.applyReq),ids=new Set(loadApplied());ids.add(id);saveApplied([...ids]);const x=rel.find(y=>Number(y.r.id)===id);if(x){draft.schedule[x.r.employee][x.di]=x.wanted;locked.add(`${x.r.employee}|${x.di}`)}repair(draft);draw([])});
  card.querySelectorAll('[data-remove-req]').forEach(b=>b.onclick=()=>{const id=Number(b.dataset.removeReq),ids=new Set(loadApplied());ids.delete(id);saveApplied([...ids]);const prev=official?.weeks?.at(-1);if(prev){locked.clear();draft=buildBase(prev);applyAccepted(draft);if(typeof applyManual==='function')try{applyManual(draft)}catch{}applyStored(draft);repair(draft);draw([])}else draw([])});
 }
 draw=function(used){applyStored(draft);originalDraw(used);mount()}
 publish=async function(){
  const issues=checkedIssues(draft);if(issues.length)return location.href='turnations.html?draft=1';
  const data=structuredClone(official),idx=data.weeks.findIndex(x=>x.dates[0]===draft.dates[0]);if(idx>=0)data.weeks[idx]=draft;else data.weeks.push(draft);data.weeks.sort((a,b)=>a.dates[0].localeCompare(b.dates[0]));data.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());
  const applied=new Set(loadApplied()),rel=relevant().filter(x=>applied.has(Number(x.r.id))&&x.r.status!=='ACCETTATA');
  try{
   await api('save_schedule',{method:'POST',body:{data}});
   for(const x of rel){try{await api('close_request',{method:'POST',body:{id:x.r.id,status:'ACCETTATA',reply:`Richiesta applicata nella nuova turnazione: ${x.wanted}`}})}catch(e){console.warn('request close failed',x.r.id,e)}}
   saveApplied([]);localStorage.removeItem('tm_planner_draft');alert('Nuova settimana pubblicata. Le richieste applicate sono state confermate.');location.href='index.html';
  }catch(e){alert(e.message)}
 }
 const style=document.createElement('style');style.textContent=`.pr-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.pr-head h3{margin:0 0 4px!important}.pr-head p{margin:0;color:#607684;font-size:12px}.pr-count{background:#ffd100;color:#003d7c;border-radius:999px;min-width:28px;height:28px;display:grid;place-items:center;font-weight:950}.pr-list{display:grid;gap:8px;margin-top:12px}.pr-item{display:flex;align-items:center;justify-content:space-between;gap:10px;border:1px solid #dbe5ec;background:#f8fafc;border-radius:14px;padding:11px}.pr-item.applied{background:#eef9f1;border-color:#b9dcc2}.pr-info b,.pr-info span,.pr-info strong,.pr-info small{display:block}.pr-info b{color:#003d7c}.pr-info span{font-size:11px;color:#667c89;margin-top:2px}.pr-info strong{font-size:14px;color:#172b3a;margin-top:5px}.pr-info small{font-size:10px;color:#6a7c87;margin-top:3px}.pr-apply,.pr-remove{border:0;border-radius:11px;padding:10px 13px;font-weight:950;flex:0 0 auto}.pr-apply{background:#ffd100;color:#003d7c}.pr-remove{background:#fff;border:1px solid #c8d7e2;color:#5f7280}.pr-ok{color:#17602a;font-weight:950;font-size:12px}.pr-empty{margin-top:10px;color:#778995;font-size:12px;padding:8px 0}@media(max-width:520px){.pr-item{align-items:flex-start}.pr-apply,.pr-remove{padding:9px 10px}}`;document.head.appendChild(style);
 setTimeout(()=>{try{if(draft){applyStored(draft);repair(draft);draw([])}}catch(e){console.warn('planner requests init',e)}},120);
})();