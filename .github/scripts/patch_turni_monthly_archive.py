from pathlib import Path

p=Path('turni-v2/app-current.js')
s=p.read_text()

# 1) Persistent local archive of published weeks + load integration.
old="async function loadSchedule(){const d=await api('get_schedule');S.schedule=d.schedule||null;return S.schedule}"
new=r'''const SCHEDULE_ARCHIVE_KEY='tm2_schedule_archive_v1';
function readScheduleArchive(){try{const x=JSON.parse(localStorage.getItem(SCHEDULE_ARCHIVE_KEY)||'[]');return Array.isArray(x)?x:[]}catch{return[]}}
function archiveSchedule(row){
  const weeks=row?.data?.weeks;if(!Array.isArray(weeks)||!weeks.length)return;
  let all=readScheduleArchive();
  for(const w of weeks){const k=w?.dates?.[0];if(!k)continue;all=all.filter(x=>x?.dates?.[0]!==k);all.push(JSON.parse(JSON.stringify(w)))}
  all.sort((a,b)=>String(a?.dates?.[0]||'').localeCompare(String(b?.dates?.[0]||'')));
  try{localStorage.setItem(SCHEDULE_ARCHIVE_KEY,JSON.stringify(all.slice(-104)))}catch{}
}
function allAdminWeeks(){
  const map=new Map();
  for(const w of readScheduleArchive()){const k=w?.dates?.[0];if(k)map.set(k,w)}
  for(const w of S.schedule?.data?.weeks||[]){const k=w?.dates?.[0];if(k)map.set(k,w)}
  return [...map.values()].sort((a,b)=>String(b?.dates?.[0]||'').localeCompare(String(a?.dates?.[0]||'')));
}
async function loadSchedule(){if(S.schedule)archiveSchedule(S.schedule);const d=await api('get_schedule');S.schedule=d.schedule||null;if(S.schedule)archiveSchedule(S.schedule);return S.schedule}'''
if old not in s: raise SystemExit('loadSchedule target not found')
s=s.replace(old,new,1)

# 2) Admin schedule: month > weeks > turn table accordions.
start=s.find('function adminSchedule(){')
end=s.find('\nfunction adminScheduleTable',start)
if start<0 or end<0: raise SystemExit('adminSchedule boundaries not found')
new_admin=r'''function monthLabelFromDate(d){return new Intl.DateTimeFormat('it-IT',{month:'long',year:'numeric'}).format(date(d)).toUpperCase()}
function adminSchedule(){
  const weeks=allAdminWeeks();
  if(!weeks.length)return shell(`<div class="empty-state"><span>▣</span><h2>Nessun turno pubblicato</h2><p>Crea o genera una nuova turnazione.</p><button class="btn primary" data-go="create">Crea turni</button></div>`);
  const groups=new Map();
  for(const w of weeks){const k=String(w.dates?.[0]||'').slice(0,7);if(!groups.has(k))groups.set(k,[]);groups.get(k).push(w)}
  const currentStarts=new Set((S.schedule?.data?.weeks||[]).map(w=>w.dates?.[0]));
  const months=[...groups.entries()].sort((a,b)=>b[0].localeCompare(a[0]));
  const actions=S.schedule?.data?.weeks?.length?`<section class="screen-actions"><button class="btn primary" id="editPublished">✎ Modifica turni</button><button class="btn secondary" id="manageWeeks">▣ Gestisci settimane</button><button class="btn secondary" data-go="create">＋ Nuovi turni</button></section>`:`<section class="screen-actions"><button class="btn primary" data-go="create">＋ Nuovi turni</button></section>`;
  return shell(`${actions}<section class="month-archive">${months.map(([k,list])=>{const ws=[...list].sort((a,b)=>String(a.dates?.[0]||'').localeCompare(String(b.dates?.[0]||'')));return `<details class="month-group"><summary><div><b>${esc(monthLabelFromDate(ws[0].dates[0]))}</b><small>${ws.length} ${ws.length===1?'settimana':'settimane'}</small></div><span>⌄</span></summary><div class="month-weeks">${ws.map((w,i)=>`<details class="archive-week"><summary><div><b>Settimana ${i+1}</b><small>${esc(fmt(w.dates[0],{day:'numeric',month:'short'}))} – ${esc(fmt(w.dates[6],{day:'numeric',month:'short'}))}${currentStarts.has(w.dates[0])?' · attuale':''}</small></div><span>⌄</span></summary><div class="archive-week-body"><section class="coverage-card"><div><b>${esc(fmt(w.dates[0],{day:'numeric',month:'long'}))} – ${esc(fmt(w.dates[6],{day:'numeric',month:'long'}))}</b><small>Turnazione pubblicata</small></div></section>${adminScheduleTable(w)}</div></details>`).join('')}</div></details>`}).join('')}</section>`)
}'''
s=s[:start]+new_admin+s[end:]

# 3) Generator summary: show accepted absence/rest requests as well as direct absences.
start=s.find('function generatePage(){')
end=s.find('\nfunction manualSetupPage()',start)
if start<0 or end<0: raise SystemExit('generatePage boundaries not found')
new_generate=r'''function generatePage(){
  const start=defaultStart(),end=add(start,20);
  const relAbs=S.absences.filter(a=>a.date_to>=start&&a.date_from<=end);
  const req=S.requests.filter(r=>r.status==='ACCETTATA'&&['RIPOSO','TURNO','CONGEDO'].includes(String(r.kind).toUpperCase())&&r.request_date>=start&&r.request_date<=end);
  const acceptedAbs=S.requests.filter(r=>r.status==='ACCETTATA'&&['FERIE','PERMESSO','RIPOSO','CONGEDO'].includes(String(r.kind||'').toUpperCase())&&r.request_date<=end&&(r.end_date||r.request_date)>=start).map(r=>({employee_name:r.employee_name,absence_type:String(r.kind).toUpperCase(),date_from:r.request_date,date_to:r.end_date||r.request_date,fromRequest:true}));
  const key=a=>[a.employee_name,String(a.absence_type||'').toUpperCase(),a.date_from,a.date_to||a.date_from].join('|');
  const existing=new Set(relAbs.map(key));
  const shown=[...relAbs,...acceptedAbs.filter(a=>!existing.has(key(a)))].sort((a,b)=>String(a.date_from||'').localeCompare(String(b.date_from||'')));
  return shell(`<section class="subnav"><button id="backCreate">‹ Metodo</button><strong>Generazione automatica</strong></section><section class="form-card"><label><span>Lunedì iniziale</span><input id="genStart" type="date" value="${esc(start)}"></label><div class="generation-status"><div><b>${relAbs.length}</b><small>assenze nel periodo</small></div><div><b>${req.length}</b><small>richieste accettate</small></div></div><button class="btn primary wide" id="runGenerate" ${S.busy?'disabled':''}>${S.busy?'Calcolo in corso…':'Genera 3 settimane'}</button><div id="genMessage"></div></section><section class="form-card"><div class="section-heading"><div><h3>Ferie e assenze</h3><p>Comprende anche le richieste accettate.</p></div><button class="btn secondary small" data-go="absences">Gestisci</button></div>${shown.length?`<div class="compact-list">${shown.map(a=>`<div><b>${esc(a.employee_name)}</b><span>${esc(a.absence_type)} · ${esc(a.date_from)} → ${esc(a.date_to||a.date_from)}${a.fromRequest?' · richiesta accettata':''}</span></div>`).join('')}</div>`:'<div class="empty-mini">Nessuna assenza o richiesta accettata nel periodo.</div>'}</section>`)
}'''
s=s[:start]+new_generate+s[end:]

# 4) Requests admin: open requests remain visible; closed grouped month > week > person.
start=s.find('function requestsAdmin(){')
end=s.find('\nfunction requestsView()',start)
if start<0 or end<0: raise SystemExit('requestsAdmin boundaries not found')
new_requests=r'''function mondayOf(d){const x=date(d),day=x.getDay()||7;x.setDate(x.getDate()-day+1);return ymd(x)}
function requestsAdmin(){
  const open=S.requests.filter(r=>r.status==='DA_VALUTARE').sort((a,b)=>String(b.request_date||'').localeCompare(String(a.request_date||''))),closed=S.requests.filter(r=>r.status!=='DA_VALUTARE');
  const months=new Map();
  for(const r of closed){const d=r.request_date||String(r.created_at||'').slice(0,10)||'0000-00-00',mk=d.slice(0,7);if(!months.has(mk))months.set(mk,[]);months.get(mk).push(r)}
  const history=[...months.entries()].sort((a,b)=>b[0].localeCompare(a[0])).map(([mk,items])=>{const weeks=new Map();for(const r of items){const d=r.request_date||String(r.created_at||'').slice(0,10);const wk=d?mondayOf(d):'0000-00-00';if(!weeks.has(wk))weeks.set(wk,[]);weeks.get(wk).push(r)}return `<details class="request-month"><summary><div><b>${items[0]?.request_date?esc(monthLabelFromDate(items[0].request_date)):esc(mk)}</b><small>${items.length} richieste chiuse</small></div><span>⌄</span></summary><div class="request-weeks">${[...weeks.entries()].sort((a,b)=>b[0].localeCompare(a[0])).map(([wk,rows])=>{const people=new Map();for(const r of rows){const n=r.employee_name||'Dipendente';if(!people.has(n))people.set(n,[]);people.get(n).push(r)}return `<details class="request-week"><summary><div><b>Settimana ${esc(fmt(wk,{day:'numeric',month:'short'}))} – ${esc(fmt(add(wk,6),{day:'numeric',month:'short'}))}</b><small>${rows.length} ${rows.length===1?'richiesta':'richieste'}</small></div><span>⌄</span></summary><div class="request-people">${[...people.entries()].sort((a,b)=>a[0].localeCompare(b[0])).map(([name,list])=>`<section class="person-request-group"><h4>${esc(name)}</h4>${list.sort((a,b)=>String(b.request_date||'').localeCompare(String(a.request_date||''))).map(r=>adminRequestCard(r,false)).join('')}</section>`).join('')}</div></details>`}).join('')}</div></details>`}).join('');
  return shell(`<section class="request-summary"><div><b>${open.length}</b><small>Da valutare</small></div><div><b>${closed.length}</b><small>Chiuse</small></div></section><section class="admin-request-list"><h3>Da valutare</h3>${open.length?open.map(r=>adminRequestCard(r,true)).join(''):'<div class="empty-mini">Nessuna richiesta aperta.</div>'}<h3 class="section-gap">Storico per mese</h3>${history||'<div class="empty-mini">Nessuna richiesta chiusa.</div>'}</section>`)
}
function adminRequestCard(r,actions){const canReopen=!actions&&r.status==='ACCETTATA';return `<article class="request-card"><div class="request-card-top"><div><b>${esc(r.employee_name)}</b><small>${esc(r.kind)} · ${r.request_date?esc(fmt(r.request_date,{day:'numeric',month:'short'})):'senza data'}</small></div>${requestBadge(r.status)}</div>${r.wanted_shift?`<p>Turno richiesto: <b>${esc(r.wanted_shift)}</b></p>`:''}${r.message?`<p>${esc(r.message)}</p>`:''}${actions?`<div class="request-actions"><button class="btn primary small" data-resolve="${r.id}" data-status="ACCETTATA">Accetta</button><button class="btn danger small" data-resolve="${r.id}" data-status="RIFIUTATA">Rifiuta</button></div>`:canReopen?`<button class="text-btn" data-resolve="${r.id}" data-status="DA_VALUTARE">Rimetti in valutazione</button>`:`<div class="request-locked">Richiesta rifiutata · stato definitivo</div>`}</article>`}'''
s=s[:start]+new_requests+s[end:]

# 5) Preserve current schedule before a new publication replaces it.
old="async function publishDraft(){if(!S.draft)return;const ok=await confirmBox('Pubblicare turnazione?','I dipendenti vedranno subito i nuovi turni nell’app.','Pubblica');if(!ok)return;try{await api('publish',{method:'POST',body:{schedule:S.draft}});S.draft=null;S.schedule=null;S.createStep='choice';await loadSchedule();toast('Turni pubblicati');go('schedule')}catch(e){toast(e.message,'error')}}"
new="async function publishDraft(){if(!S.draft)return;const ok=await confirmBox('Pubblicare turnazione?','I dipendenti vedranno subito i nuovi turni nell’app.','Pubblica');if(!ok)return;try{archiveSchedule(S.schedule);await api('publish',{method:'POST',body:{schedule:S.draft}});S.draft=null;S.schedule=null;S.createStep='choice';await loadSchedule();toast('Turni pubblicati');go('schedule')}catch(e){toast(e.message,'error')}}"
if old not in s: raise SystemExit('publishDraft target not found')
s=s.replace(old,new,1)

# Cache bump.
s=s.replace('current-20260913-5','current-20260913-6')
p.write_text(s)

css=Path('turni-v2/app-current.css')
c=css.read_text()
styles=r'''
/* Monthly archive and nested request history */
.month-archive,.month-weeks,.request-weeks{display:grid;gap:9px}.month-group,.archive-week,.request-month,.request-week{background:#fff;border:1px solid var(--line);border-radius:12px;overflow:hidden;box-shadow:var(--shadow)}.month-group>summary,.request-month>summary{min-height:66px;padding:12px 14px;display:flex;align-items:center;justify-content:space-between;list-style:none;cursor:pointer}.archive-week>summary,.request-week>summary{min-height:58px;padding:10px 12px;display:flex;align-items:center;justify-content:space-between;list-style:none;cursor:pointer;background:#f8fafc}.month-group summary::-webkit-details-marker,.archive-week summary::-webkit-details-marker,.request-month summary::-webkit-details-marker,.request-week summary::-webkit-details-marker{display:none}.month-group summary div b,.month-group summary div small,.archive-week summary div b,.archive-week summary div small,.request-month summary div b,.request-month summary div small,.request-week summary div b,.request-week summary div small{display:block}.month-group>summary b,.request-month>summary b{font-size:14px;color:var(--text)}.month-group summary small,.archive-week summary small,.request-month summary small,.request-week summary small{font-size:9px;color:var(--muted);margin-top:3px}.month-group summary>span,.archive-week summary>span,.request-month summary>span,.request-week summary>span{font-size:20px;color:var(--blue);transition:.18s}.month-group[open]>summary>span,.archive-week[open]>summary>span,.request-month[open]>summary>span,.request-week[open]>summary>span{transform:rotate(180deg)}.month-weeks,.request-weeks{padding:0 10px 10px}.archive-week-body{padding:10px}.archive-week-body .coverage-card{margin:0 0 9px;box-shadow:none}.archive-week-body .schedule-table-card{box-shadow:none}.request-people{display:grid;gap:10px;padding:10px}.person-request-group{display:grid;gap:7px}.person-request-group h4{margin:1px 2px 0;font-size:11px;color:var(--blue);text-transform:uppercase;letter-spacing:.03em}.request-month,.request-week{box-shadow:none}.request-week{border-radius:10px}.request-locked{margin-top:8px;padding:7px 9px;border-radius:7px;background:#f5f6f8;color:#8a96a5;font-size:9px;font-weight:700}.admin-request-list>.request-month{margin-top:7px}.compact-list>div span{line-height:1.35}
'''
if '/* Monthly archive and nested request history */' not in c:c+=styles
css.write_text(c)

ip=Path('turni-v2/index.html')
ip.write_text(ip.read_text().replace('current-20260913-5','current-20260913-6'))
sw=Path('turni-v2/sw.js')
sw.write_text(sw.read_text().replace('turni-current-20260913-v5','turni-current-20260913-v6'))
