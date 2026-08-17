(()=>{
 let selectedDay=0;
 function firstStart(s){const m=String(s||'').match(/(\d{1,2}):(\d{2})/);return m?(+m[1]*60)+(+m[2]):null}
 function classify(s){if(!s||s==='—'||ABSENCES.has(s))return 'absence';const st=firstStart(s);return st!==null&&st<810?'morning':'afternoon'}
 function dayName(d){return new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric'}).format(new Date(d+'T12:00:00'))}
 function renderDaily(host,w){
   selectedDay=Math.max(0,Math.min(6,selectedDay));
   const i=selectedDay,date=w.dates[i],rows=Object.keys(w.schedule).map(n=>({n,s:(w.schedule[n]||[])[i]||'—'}));
   const morning=rows.filter(x=>classify(x.s)==='morning'),afternoon=rows.filter(x=>classify(x.s)==='afternoon'),absent=rows.filter(x=>classify(x.s)==='absence'&&x.s!=='—');
   const item=x=>`<div class="hdv-person"><b>${esc(x.n)}</b><span>${esc(x.s)}</span></div>`;
   host.innerHTML=`<div class="hdv-head"><div><span class="kicker">Vista giornaliera</span><h2>Turni per giorno</h2></div><strong>${esc(fmtDate(date))}</strong></div><div class="hdv-tabs">${w.dates.map((d,di)=>`<button type="button" class="${di===i?'active':''}" data-hdv-day="${di}"><b>${esc(dayName(d).split(' ')[0])}</b><span>${new Date(d+'T12:00:00').getDate()}</span></button>`).join('')}</div><div class="hdv-cols"><section><h3>☀️ Mattina</h3>${morning.length?morning.map(item).join(''):'<div class="hdv-empty">Nessun turno</div>'}</section><section><h3>🌙 Pomeriggio</h3>${afternoon.length?afternoon.map(item).join(''):'<div class="hdv-empty">Nessun turno</div>'}</section></div><section class="hdv-abs"><h3>Assenze / Stati</h3>${absent.length?`<div class="hdv-abs-grid">${absent.map(item).join('')}</div>`:'<div class="hdv-empty">Nessuna assenza o riposo</div>'}</section>`;
   host.querySelectorAll('[data-hdv-day]').forEach(b=>b.onclick=()=>{selectedDay=+b.dataset.hdvDay;renderDaily(host,w)});
 }
 function mount(){
   if(typeof state==='undefined'||!state.user?.admin||!state.data?.weeks?.length)return;
   const admin=document.querySelector('.admin-schedule-focus');if(!admin)return;
   const w=state.data.weeks[state.week];if(!w)return;
   const list=admin.querySelector('.admin-turn-list');
   if(list&&!list.closest('#employeeScheduleDetails')){
     const details=document.createElement('details');details.id='employeeScheduleDetails';details.className='hdv-details';details.innerHTML='<summary><div><b>Turni per dipendente</b><small>Apri per vedere tutti i dipendenti</small></div><span>⌄</span></summary><div class="hdv-employee-body"></div>';
     list.parentNode.insertBefore(details,list);details.querySelector('.hdv-employee-body').appendChild(list);
   }
   let daily=admin.querySelector('#homeDailySchedule');
   const weekKey=w.dates[0];
   if(daily&&daily.dataset.week===weekKey&&daily.dataset.ready==='1')return;
   if(!daily){daily=document.createElement('section');daily.id='homeDailySchedule';daily.className='hdv-card';const det=admin.querySelector('#employeeScheduleDetails');if(det)det.insertAdjacentElement('afterend',daily);else admin.appendChild(daily)}
   if(daily.dataset.week!==weekKey){selectedDay=0;daily.dataset.week=weekKey}
   renderDaily(daily,w);daily.dataset.ready='1';
 }
 let queued=false;
 const obs=new MutationObserver(()=>{if(queued)return;queued=true;requestAnimationFrame(()=>{queued=false;mount()})});obs.observe(document.getElementById('app')||document.documentElement,{subtree:true,childList:true});setTimeout(mount,80);
 const style=document.createElement('style');style.textContent=`.hdv-details{margin-top:12px;border:1px solid var(--line);border-radius:18px;overflow:hidden;background:#fff}.hdv-details>summary{list-style:none;cursor:pointer;padding:14px;display:flex;align-items:center;justify-content:space-between;color:var(--blue-deep);background:#eef5fa}.hdv-details>summary::-webkit-details-marker{display:none}.hdv-details>summary b,.hdv-details>summary small{display:block}.hdv-details>summary b{font-size:15px}.hdv-details>summary small{font-size:10px;color:var(--muted);margin-top:2px}.hdv-details>summary span{font-size:20px}.hdv-employee-body{padding:10px}.hdv-card{margin-top:12px;border:1px solid var(--line);border-radius:20px;padding:12px;background:#f7fafc}.hdv-head{display:flex;justify-content:space-between;align-items:flex-end;gap:10px}.hdv-head h2{margin:3px 0 0;color:var(--blue-deep);font-size:20px}.hdv-head>strong{font-size:12px;color:var(--blue-deep)}.hdv-tabs{display:grid;grid-template-columns:repeat(7,1fr);gap:5px;margin:11px 0}.hdv-tabs button{border:1px solid #ccdbe5;background:#fff;color:#003d7c;border-radius:11px;padding:8px 3px}.hdv-tabs b,.hdv-tabs span{display:block}.hdv-tabs b{font-size:9px;text-transform:capitalize}.hdv-tabs span{font-size:13px;font-weight:950}.hdv-tabs button.active{background:#0067b1;color:#fff;border-color:#0067b1}.hdv-cols{display:grid;grid-template-columns:1fr 1fr;gap:8px}.hdv-cols section,.hdv-abs{background:#fff;border:1px solid #dbe5ec;border-radius:15px;padding:10px}.hdv-cols h3,.hdv-abs h3{margin:0 0 7px;color:#003d7c;font-size:13px}.hdv-person{display:flex;justify-content:space-between;gap:8px;padding:8px 2px;border-top:1px solid #edf1f4}.hdv-person:first-of-type{border-top:0}.hdv-person b{color:#003d7c;font-size:11px}.hdv-person span{font-size:10px;text-align:right;font-weight:800}.hdv-abs{margin-top:8px}.hdv-abs-grid{display:grid;grid-template-columns:1fr 1fr;column-gap:12px}.hdv-abs .hdv-person span{color:#806400}.hdv-empty{font-size:11px;color:#7b8a94;padding:7px 0}@media(max-width:600px){.hdv-card{padding:9px}.hdv-tabs{gap:3px}.hdv-tabs button{padding:7px 1px}.hdv-cols{gap:6px}.hdv-cols section{padding:8px 6px}.hdv-person{display:block}.hdv-person span{display:block;text-align:left;margin-top:3px}.hdv-abs-grid{grid-template-columns:1fr 1fr}}`;document.head.appendChild(style);
})();