(()=>{
'use strict';
const box=document.getElementById('app');
const fail=e=>{console.error(e);if(box)box.innerHTML=`<div class="error" style="margin:20px"><b>Errore Nuovi Turni</b><br>${typeof esc==='function'?esc(e?.message||e):String(e?.message||e)}</div>`};
(async()=>{
 try{
  const r=await fetch('monthly-turns-v2.js?v=61',{cache:'no-store'});
  if(!r.ok)throw new Error(`Motore mensile non caricato (${r.status})`);
  let c=await r.text();

  const replaceExact=(from,to,label)=>{
   if(!c.includes(from))throw new Error(`Patch mensile non applicabile: ${label}`);
   c=c.replace(from,to);
  };

  replaceExact(
   "function choose(w,list,used,i){return list.filter(n=>!used.has(n)&&!OFF.has(w.schedule[n][i])).sort((a,b)=>score(w,a,i)-score(w,b,i))[0]||null}",
   "function choose(w,list,used,i){return list.filter(n=>!used.has(n)&&!PROTECTED.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO'&&!works(w.schedule[n][i])).sort((a,b)=>score(w,a,i)-score(w,b,i))[0]||null}",
   'disponibilità dipendenti'
  );

  replaceExact(
   "const avail=RESP.filter(n=>!OFF.has(w.schedule[n][i]));",
   "const avail=RESP.filter(n=>!PROTECTED.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO'&&!works(w.schedule[n][i]));",
   'disponibilità responsabili'
  );

  replaceExact(
   "const available=OPS.filter(n=>!OFF.has(w.schedule[n][i])),used=new Set();",
   "const available=OPS.filter(n=>!PROTECTED.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO'),used=new Set(OPS.filter(n=>works(w.schedule[n][i])));",
   'disponibilità operativi'
  );

  replaceExact(
   "function buildMonth(y,m){const w=blankMonth(y,m);for(let i=0;i<w.dates.length;i++){",
   "function buildMonth(y,m){const w=blankMonth(y,m);applyAccepted(w);for(let i=0;i<w.dates.length;i++){",
   'richieste prima della generazione'
  );

  replaceExact(
   "if(iso(sun)>w.dates.at(-1))return false;",
   "",
   'riposo a cavallo mese'
  );

  replaceExact(
   "function restDateForSunday(sun,n){const people=[sundayResp(sun),...sundayCrew(sun)],idx=people.indexOf(n);const offsets=[-4,-5,-3,-2];const x=new Date(sun);x.setDate(x.getDate()+offsets[Math.max(0,idx)]);return iso(x)}",
   "function restDateForSunday(sun,n){const people=[sundayResp(sun),...sundayCrew(sun)],idx=Math.max(0,people.indexOf(n)),offsets=[-5,-4,-3,-2],cycle=((sundayIndex(sun,RESP_ANCHOR)%4)+4)%4,x=new Date(sun);x.setDate(x.getDate()+offsets[(idx+cycle)%4]);return iso(x)}",
   'rotazione riposi'
  );

  replaceExact(
   "function prevStreak(n,w){const prev=official.weeks?.filter(x=>String(x.dates?.at(-1)||'')<w.dates[0]).sort((a,b)=>String(a.dates.at(-1)).localeCompare(String(b.dates.at(-1)))).at(-1);if(!prev)return 0;let s=0;for(let i=prev.dates.length-1;i>=0;i--){if(works(prev.schedule?.[n]?.[i]))s++;else break}return s}",
   "function prevStreak(n,w){const entries=[];for(const pw of (official.weeks||[]))for(let j=0;j<(pw.dates||[]).length;j++)if(pw.dates[j]<w.dates[0])entries.push({d:pw.dates[j],s:pw.schedule?.[n]?.[j]});entries.sort((a,b)=>a.d.localeCompare(b.d));let streak=0,last=null;for(let k=entries.length-1;k>=0;k--){const e=entries[k];if(last){const gap=(new Date(last+'T12:00:00')-new Date(e.d+'T12:00:00'))/86400000;if(gap!==1)break}if(works(e.s)){streak++;last=e.d}else break}return streak}",
   'continuità giorni lavorati'
  );

  replaceExact(
   "const key=weekMonday(w.dates[i]),hasRest=w.dates.some((x,k)=>weekMonday(x)===key&&w.schedule[n][k]==='RIPOSO');",
   "const key=weekMonday(w.dates[i]),hasRest=w.dates.some((x,k)=>weekMonday(x)===key&&w.schedule[n][k]==='RIPOSO')||(official.weeks||[]).some(pw=>(pw.dates||[]).some((x,k)=>weekMonday(x)===key&&pw.schedule?.[n]?.[k]==='RIPOSO'));",
   'riposo domenicale a cavallo mese'
  );

  const oldPublish="async function publish(){const r=fiveChecks(draft);if(r.errors.length)return alert('Ci sono ancora errori bloccanti.');const data=structuredClone(official||{weeks:[]});data.weeks=Array.isArray(data.weeks)?data.weeks:[];const idx=data.weeks.findIndex(x=>x.period==='month'&&x.year===draft.year&&x.month===draft.month);if(idx>=0)data.weeks[idx]=draft;else data.weeks.push(draft);data.weeks.sort((a,b)=>String(a.dates?.[0]||'').localeCompare(String(b.dates?.[0]||'')));data.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());await api('save_schedule',{method:'POST',body:{data}});localStorage.removeItem('tm_planner_draft');alert('Mese pubblicato dopo 5 controlli completi.');location.href='index.html'}";
  const newPublish="async function publish(){const r=fiveChecks(draft);if(r.errors.length)return alert('Ci sono ancora errori bloccanti.');const data=structuredClone(official||{weeks:[]});data.weeks=Array.isArray(data.weeks)?data.weeks:[];const monthSet=new Set(draft.dates);data.weeks=data.weeks.filter(pw=>!(pw.dates||[]).some(d=>monthSet.has(d)));const keys=[...new Set(draft.dates.map(weekMonday))];for(const k of keys){const idx=[];draft.dates.forEach((d,i)=>{if(weekMonday(d)===k)idx.push(i)});const draftDates=idx.map(i=>draft.dates[i]);const old=data.weeks.find(pw=>(pw.dates||[]).some(d=>weekMonday(d)===k));const allDates=[...new Set([...(old?.dates||[]),...draftDates])].sort();const schedule={};for(const n of NAMES){schedule[n]=allDates.map(d=>{const di=draft.dates.indexOf(d);if(di>=0)return draft.schedule[n][di];const oi=old?.dates?.indexOf(d)??-1;return oi>=0?old.schedule?.[n]?.[oi]||'—':'—'})}if(old)data.weeks=data.weeks.filter(pw=>pw!==old);data.weeks.push({label:allDates[0]+' / '+allDates.at(-1),dates:allDates,schedule,period:'week',sourceMonth:`${draft.year}-${String(draft.month).padStart(2,'0')}`})}data.weeks.sort((a,b)=>String(a.dates?.[0]||'').localeCompare(String(b.dates?.[0]||'')));data.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());await api('save_schedule',{method:'POST',body:{data}});localStorage.removeItem('tm_planner_draft');alert('Mese pubblicato dopo 5 controlli completi.');location.href='index.html'}";
  replaceExact(oldPublish,newPublish,'pubblicazione mensile');

  new Function('"use strict";\n'+c)();
 }catch(e){fail(e)}
})();
})();