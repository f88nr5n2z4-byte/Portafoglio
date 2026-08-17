(()=>{
 function currentDayIndex(){
  const title=document.querySelector('#turnReviewBack .tr-head h2')?.textContent?.trim();
  if(!title||!draft?.dates)return -1;
  return draft.dates.findIndex(d=>fmtDate(d)===title);
 }
 function persistDraft(){try{const pd=JSON.parse(localStorage.getItem('tm_planner_draft')||'{}');pd.week=draft;pd.issues=validateWeek(draft);pd.createdAt=new Date().toISOString();localStorage.setItem('tm_planner_draft',JSON.stringify(pd))}catch{}}
 function refreshReview(){const active=document.querySelector('#turnReviewBack [data-review-day].active');if(active)active.click()}
 function refreshMainAndReview(di){
  const keepDay=di;
  const reviewOpen=!!document.getElementById('turnReviewBack');
  if(reviewOpen)document.getElementById('turnReviewBack')?.remove();
  draw([]);
  if(reviewOpen)setTimeout(()=>{
   const btn=document.getElementById('checkTurnsBtn');
   if(btn){btn.click();setTimeout(()=>{const day=document.querySelector(`#turnReviewBack [data-review-day="${keepDay}"]`);if(day)day.click()},0)}
  },0);
 }
 function openEditor(n,di){
  const cur=draft.schedule[n][di]||'—',ps=spans(cur),fmt=x=>`${String(Math.floor(x/60)).padStart(2,'0')}:${String(x%60).padStart(2,'0')}`;
  document.body.insertAdjacentHTML('beforeend',`<div class="tr-edit-back" id="trEditBack"><div class="tr-edit-sheet"><div class="tr-edit-title"><div><b>${esc(n)}</b><small>${esc(fmtDate(draft.dates[di]))}</small></div><button id="trEditClose">×</button></div><div class="tr-edit-current">Turno attuale: <b>${esc(cur)}</b></div><div class="tr-edit-tabs"><button class="active" data-tetab="quick">Rapido</button><button data-tetab="status">Assenza/Stato</button><button data-tetab="custom">Personalizza</button></div><div id="teQuick" class="tr-edit-tab"><select id="teQuickShift">${SHIFT_OPTIONS.filter(s=>!ABSENCES.has(s)).map(s=>`<option ${s===cur?'selected':''}>${esc(s)}</option>`).join('')}</select></div><div id="teStatus" class="tr-edit-tab hidden"><div class="tr-edit-statuses">${['RIPOSO','FERIE','MALATTIA','MATERNITÀ','PERMESSO'].map(s=>`<button type="button" data-testatus="${s}">${s}</button>`).join('')}</div></div><div id="teCustom" class="tr-edit-tab hidden"><b>Prima fascia</b><div class="two"><label>Inizio<input id="teS1" type="time" step="900" value="${ps[0]?fmt(ps[0][0]):'07:00'}"></label><label>Fine<input id="teE1" type="time" step="900" value="${ps[0]?fmt(ps[0][1]):'14:00'}"></label></div><b>Seconda fascia <small>(opzionale)</small></b><div class="two"><label>Inizio<input id="teS2" type="time" step="900" value="${ps[1]?fmt(ps[1][0]):''}"></label><label>Fine<input id="teE2" type="time" step="900" value="${ps[1]?fmt(ps[1][1]):''}"></label></div><p class="tr-edit-help">Puoi inserire qualsiasi turno continuo o spezzato.</p></div><button class="tr-edit-save" id="trEditSave">Applica modifica</button></div></div>`);
  let mode='quick',status='RIPOSO';
  document.querySelectorAll('[data-tetab]').forEach(b=>b.onclick=()=>{mode=b.dataset.tetab;document.querySelectorAll('[data-tetab]').forEach(x=>x.classList.toggle('active',x===b));['Quick','Status','Custom'].forEach(x=>document.getElementById('te'+x).classList.add('hidden'));document.getElementById('te'+mode[0].toUpperCase()+mode.slice(1)).classList.remove('hidden')});
  document.querySelectorAll('[data-testatus]').forEach(b=>b.onclick=()=>{status=b.dataset.testatus;document.querySelectorAll('[data-testatus]').forEach(x=>x.classList.toggle('picked',x===b))});
  document.querySelector('[data-testatus="RIPOSO"]')?.classList.add('picked');
  document.getElementById('trEditClose').onclick=()=>document.getElementById('trEditBack')?.remove();
  document.getElementById('trEditSave').onclick=()=>{
   let s=document.getElementById('teQuickShift').value;
   if(mode==='status')s=status;
   if(mode==='custom'){
    const a=document.getElementById('teS1').value,b=document.getElementById('teE1').value,c=document.getElementById('teS2').value,z=document.getElementById('teE2').value;
    if(!a||!b||hm(b)<=hm(a))return alert('Controlla la prima fascia.');
    s=`${a}-${b}`;
    if(c||z){if(!c||!z||hm(z)<=hm(c)||hm(c)<hm(b))return alert('Controlla la seconda fascia.');s+=` / ${c}-${z}`}
   }
   draft.schedule[n][di]=s;
   locked.add(`${n}|${di}`);
   persistDraft();
   document.getElementById('trEditBack')?.remove();
   refreshMainAndReview(di);
  };
 }
 function wire(){
  const back=document.getElementById('turnReviewBack');if(!back)return;
  const di=currentDayIndex();if(di<0)return;
  back.querySelectorAll('.tr-person').forEach(row=>{
   if(row.dataset.editReady)return;const n=row.querySelector('b')?.textContent?.trim();if(!n||!draft.schedule[n])return;
   row.dataset.editReady='1';row.classList.add('tr-editable');row.setAttribute('role','button');row.setAttribute('tabindex','0');
   if(!row.querySelector('.tr-edit-hint'))row.insertAdjacentHTML('beforeend','<small class="tr-edit-hint">Tocca per modificare</small>');
   const go=()=>openEditor(n,di);row.onclick=go;row.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();go()}};
  });
 }
 const obs=new MutationObserver(wire);obs.observe(document.documentElement,{subtree:true,childList:true});setTimeout(wire,0);
 const style=document.createElement('style');style.textContent=`.tr-editable{cursor:pointer;border-radius:9px;padding-left:7px!important;padding-right:7px!important}.tr-editable:active{background:#eef6fc}.tr-edit-hint{display:block;font-size:8px!important;color:#6b7e8b!important;margin-top:3px}.tr-edit-back{position:fixed;inset:0;background:rgba(0,31,65,.55);z-index:40000;display:flex;align-items:flex-end;justify-content:center;padding:10px}.tr-edit-sheet{width:min(620px,100%);background:#fff;border-radius:20px 20px 13px 13px;padding:15px;max-height:90vh;overflow:auto}.tr-edit-title{display:flex;justify-content:space-between}.tr-edit-title b,.tr-edit-title small{display:block}.tr-edit-title b{color:#003d7c;font-size:18px}.tr-edit-title button{border:0;background:#eef3f6;border-radius:9px;width:34px;height:34px;font-size:22px}.tr-edit-current{background:#eef5fa;border-radius:11px;padding:9px;margin:10px 0}.tr-edit-tabs{display:grid;grid-template-columns:repeat(3,1fr);gap:6px;margin-bottom:10px}.tr-edit-tabs button{border:1px solid #c9d8e3;background:#fff;border-radius:10px;padding:9px;color:#003d7c;font-weight:900}.tr-edit-tabs button.active{background:#0067b1;color:#fff}.tr-edit-tab select,.tr-edit-tab input{width:100%;box-sizing:border-box;border:1px solid #c8d7e2;border-radius:10px;padding:10px;font-size:16px;background:#fff}.tr-edit-statuses{display:grid;grid-template-columns:1fr 1fr;gap:7px}.tr-edit-statuses button{border:1px solid #cbd9e3;background:#fff;border-radius:10px;padding:10px;font-weight:900;color:#003d7c}.tr-edit-statuses button.picked{background:#ffd500}.tr-edit-help{font-size:11px;color:#6b7b86}.tr-edit-save{width:100%;border:0;background:#0067b1;color:#fff;border-radius:12px;padding:12px;font-weight:950;margin-top:12px}`;document.head.appendChild(style);
})();