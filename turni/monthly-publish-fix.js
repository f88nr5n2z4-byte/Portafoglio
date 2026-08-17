(()=>{
 function labelWeek(dates){const a=new Date(dates[0]+'T12:00:00'),b=new Date(dates.at(-1)+'T12:00:00'),m=x=>new Intl.DateTimeFormat('it-IT',{month:'short'}).format(x).replace('.','');return a.getMonth()===b.getMonth()?`${a.getDate()}–${b.getDate()} ${m(a)}`:`${a.getDate()} ${m(a)} – ${b.getDate()} ${m(b)}`}
 function splitMonth(w){const keys=[];for(const d of w.dates){const k=weekMonday(d);if(!keys.includes(k))keys.push(k)}return keys.map(k=>{const idx=[];w.dates.forEach((d,i)=>{if(weekMonday(d)===k)idx.push(i)});const dates=idx.map(i=>w.dates[i]),schedule={};for(const n of NAMES)schedule[n]=idx.map(i=>w.schedule[n][i]);return{label:labelWeek(dates),dates,schedule,period:'week',sourceMonth:`${w.year}-${String(w.month).padStart(2,'0')}`}})}
 publish=async function(){
  const r=fiveChecks(draft);if(r.errors.length)return alert('Ci sono ancora errori bloccanti.');
  const data=structuredClone(official||{weeks:[]});data.weeks=Array.isArray(data.weeks)?data.weeks:[];
  const monthSet=new Set(draft.dates);data.weeks=data.weeks.filter(w=>!(w.dates||[]).some(d=>monthSet.has(d)));
  data.weeks.push(...splitMonth(draft));data.weeks.sort((a,b)=>String(a.dates?.[0]||'').localeCompare(String(b.dates?.[0]||'')));
  data.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());
  await api('save_schedule',{method:'POST',body:{data}});localStorage.removeItem('tm_planner_draft');alert('Mese pubblicato dopo 5 controlli completi.');location.href='index.html';
 };
})();