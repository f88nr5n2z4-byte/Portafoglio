(()=>{
 const oldDraw=draw;
 function dayIssues(w,i){const p=fmtDate(w.dates[i])+':';return validateWeek(w).filter(x=>String(x).startsWith(p))}
 function mountEditablePreview(){
  if(!draft)return;
  const grid=document.querySelector('.miniweek');if(!grid)return;
  const names=Object.keys(draft.schedule);
  const cells=[...grid.children];
  // struttura: 1 vuota + 7 header + per ogni dipendente: nome + 7 celle
  let idx=8;
  for(const n of names){
   idx++; // salta nome
   for(let di=0;di<7;di++,idx++){
    const cell=cells[idx];if(!cell)continue;
    cell.classList.add('inline-edit-cell');
    cell.setAttribute('role','button');
    cell.setAttribute('tabindex','0');
    const s=draft.schedule[n][di]||'—';
    const issues=dayIssues(draft,di);
    cell.innerHTML=`<span>${esc(s)}</span><small>Tocca per modificare</small>${issues.length?`<em>${issues.length} err.</em>`:''}`;
    const open=()=>openInlineEditor(n,di);
    cell.onclick=open;
    cell.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();open()}};
   }
  }
 }
 function openInlineEditor(n,di){
  const cur=draft.schedule[n][di]||'—',ps=spans(cur),fmt=x=>`${String(Math.floor(x/60)).padStart(2,'0')}:${String(x%60).padStart(2,'0')}`;
  document.body.insertAdjacentHTML('beforeend',`<div class="inline-modal" id="inlineModal"><div class="inline-sheet"><div class="inline-title"><div><b>${esc(n)}</b><small>${esc(fmtDate(draft.dates[di]))}</small></div><button id="inlineClose">×</button></div><div class="inline-current">Turno attuale: <b>${esc(cur)}</b></div><div class="inline-tabs"><button class="active" data-itab="quick">Rapido</button><button data-itab="status">Assenza/Stato</button><button data-itab="custom">Personalizza</button></div><div id="iQuick" class="inline-tab"><select id="iQuickShift">${SHIFT_OPTIONS.filter(s=>!ABSENCES.has(s)).map(s=>`<option ${s===cur?'selected':''}>${esc(s)}</option>`).join('')}</select></div><div id="iStatus" class="inline-tab hidden"><div class="inline-statuses">${['RIPOSO','FERIE','MALATTIA','MATERNITÀ','PERMESSO'].map(s=>`<button type="button" data-istatus="${s}">${s}</button>`).join('')}</div></div><div id="iCustom" class="inline-tab hidden"><b>Prima fascia</b><div class="two"><label>Inizio<input id="iS1" type="time" step="900" value="${ps[0]?fmt(ps[0][0]):'07:00'}"></label><label>Fine<input id="iE1" type="time" step="900" value="${ps[0]?fmt(ps[0][1]):'14:00'}"></label></div><b>Seconda fascia <small>(opzionale)</small></b><div class="two"><label>Inizio<input id="iS2" type="time" step="900" value="${ps[1]?fmt(ps[1][0]):''}"></label><label>Fine<input id="iE2" type="time" step="900" value="${ps[1]?fmt(ps[1][1]):''}"></label></div><p class="inline-help">Puoi inserire qualsiasi turno continuo o spezzato.</p></div><button class="inline-save" id="inlineSave">Applica modifica</button></div></div>`);
  let mode='quick',status='RIPOSO';
  document.querySelectorAll('[data-itab]').forEach(b=>b.onclick=()=>{mode=b.dataset.itab;document.querySelectorAll('[data-itab]').forEach(x=>x.classList.toggle('active',x===b));['Quick','Status','Custom'].forEach(x=>document.getElementById('i'+x).classList.add('hidden'));document.getElementById('i'+mode[0].toUpperCase()+mode.slice(1)).classList.remove('hidden')});
  document.querySelectorAll('[data-istatus]').forEach(b=>b.onclick=()=>{status=b.dataset.istatus;document.querySelectorAll('[data-istatus]').forEach(x=>x.classList.toggle('picked',x===b))});
  document.querySelector('[data-istatus="RIPOSO"]')?.classList.add('picked');
  document.getElementById('inlineClose').onclick=()=>document.getElementById('inlineModal').remove();
  document.getElementById('inlineSave').onclick=()=>{
   let s=document.getElementById('iQuickShift').value;
   if(mode==='status')s=status;
   if(mode==='custom'){
    const a=document.getElementById('iS1').value,b=document.getElementById('iE1').value,c=document.getElementById('iS2').value,z=document.getElementById('iE2').value;
    if(!a||!b||hm(b)<=hm(a))return alert('Controlla la prima fascia.');
    s=`${a}-${b}`;
    if(c||z){if(!c||!z||hm(z)<=hm(c)||hm(c)<hm(b))return alert('Controlla la seconda fascia.');s+=` / ${c}-${z}`}
   }
   draft.schedule[n][di]=s;
   locked.add(`${n}|${di}`);
   try{
    const pd=JSON.parse(localStorage.getItem('tm_planner_draft')||'{}');
    pd.week=draft;pd.issues=validateWeek(draft);pd.createdAt=new Date().toISOString();
    localStorage.setItem('tm_planner_draft',JSON.stringify(pd));
   }catch{}
   document.getElementById('inlineModal').remove();
   draw([]);
  };
 }
 draw=function(used){oldDraw(used);setTimeout(mountEditablePreview,0)};
 const style=document.createElement('style');style.textContent=`.inline-edit-cell{cursor:pointer;border-radius:8px!important;position:relative}.inline-edit-cell:hover,.inline-edit-cell:active{background:#eef6fc!important}.inline-edit-cell span,.inline-edit-cell small,.inline-edit-cell em{display:block}.inline-edit-cell small{font-size:8px;color:#6f8290;margin-top:3px;font-style:normal}.inline-edit-cell em{font-size:8px;color:#8a6500;font-weight:900;font-style:normal;margin-top:2px}.inline-modal{position:fixed;inset:0;background:rgba(0,31,65,.48);z-index:30000;display:flex;align-items:flex-end;justify-content:center;padding:10px}.inline-sheet{width:min(620px,100%);background:#fff;border-radius:20px 20px 13px 13px;padding:15px;max-height:90vh;overflow:auto}.inline-title{display:flex;justify-content:space-between}.inline-title b,.inline-title small{display:block}.inline-title b{color:#003d7c;font-size:18px}.inline-title button{border:0;background:#eef3f6;border-radius:9px;width:34px;height:34px;font-size:22px}.inline-current{background:#eef5fa;border-radius:11px;padding:9px;margin:10px 0}.inline-tabs{display:grid;grid-template-columns:repeat(3,1fr);gap:6px;margin-bottom:10px}.inline-tabs button{border:1px solid #c9d8e3;background:#fff;border-radius:10px;padding:9px;color:#003d7c;font-weight:900}.inline-tabs button.active{background:#0067b1;color:#fff}.inline-tab select,.inline-tab input{width:100%;box-sizing:border-box;border:1px solid #c8d7e2;border-radius:10px;padding:10px;font-size:16px;background:#fff}.inline-statuses{display:grid;grid-template-columns:1fr 1fr;gap:7px}.inline-statuses button{border:1px solid #cbd9e3;background:#fff;border-radius:10px;padding:10px;font-weight:900;color:#003d7c}.inline-statuses button.picked{background:#ffd500}.inline-help{font-size:11px;color:#6b7b86}.inline-save{width:100%;border:0;background:#0067b1;color:#fff;border-radius:12px;padding:12px;font-weight:950;margin-top:12px}`;document.head.appendChild(style);
})();