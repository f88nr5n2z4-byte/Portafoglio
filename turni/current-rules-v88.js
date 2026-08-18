(()=>{
'use strict';
const RR=['Umberto','Fabio','Emanuele'];
const CASHIERS=['Stefania B','Giada','Romina','Stefania F'];
const CASH_BACKUP=['Giuliano','Daniele','Manuel'];
const SALA=['Giuliano','Daniele','Manuel','Paolo','Marco'];
const OFF=new Set(['RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—']);
const PROTECTED=new Set(['FERIE','PERMESSO','MATERNITÀ','MALATTIA']);
const mins=t=>{const [h,m]=String(t).split(':').map(Number);return Number.isFinite(h)&&Number.isFinite(m)?h*60+m:NaN};
const spansOf=s=>{if(!s||OFF.has(s))return[];return String(s).split('/').map(x=>x.trim()).map(x=>{const [a,b]=x.split('-').map(v=>mins(v.trim()));return Number.isFinite(a)&&Number.isFinite(b)&&b>a?[a,b]:null}).filter(Boolean)};
const works=s=>spansOf(s).length>0;
const at=(s,t)=>{const x=mins(t);return spansOf(s).some(([a,b])=>a<=x&&x<b)};
const starts=(s,t)=>{const x=mins(t);return spansOf(s).some(([a])=>a===x)};
const every15=(a,b,fn)=>{for(let t=mins(a);t<mins(b);t+=15){if(!fn(t))return false}return true};
const atMin=(s,t)=>spansOf(s).some(([a,b])=>a<=t&&t<b);
const active=(w,i,t,pred=()=>true)=>Object.keys(w.schedule||{}).filter(n=>pred(n)&&atMin(w.schedule[n]?.[i],t));
const cashActive=(w,i,t)=>active(w,i,t,n=>CASHIERS.includes(n)||CASH_BACKUP.includes(n));
function effectiveSala(w,i,t){const dedicated=active(w,i,t,n=>CASHIERS.includes(n));const backupUsed=dedicated.length?null:active(w,i,t,n=>CASH_BACKUP.includes(n))[0];return active(w,i,t,n=>SALA.includes(n)&&n!==backupUsed)}
function label(iso){try{return typeof fmtDate==='function'?fmtDate(iso):new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(iso+'T12:00:00'))}catch{return iso}}
function validateWeekCurrent(w){
 const issues=[];if(!w?.dates||!w?.schedule)return issues;
 w.dates.forEach((iso,i)=>{
  const dow=new Date(iso+'T12:00:00').getDay();
  const working=Object.keys(w.schedule).filter(n=>works(w.schedule[n]?.[i]));
  if(dow===0){
   if(working.length!==4)issues.push(`${label(iso)}: domenica ${working.length} persone invece di 4`);
   if(working.some(n=>w.schedule[n]?.[i]!=='08:00-13:00'))issues.push(`${label(iso)}: la domenica chi lavora deve fare 08:00-13:00`);
   if(working.filter(n=>RR.includes(n)).length!==1)issues.push(`${label(iso)}: domenica deve esserci esattamente 1 responsabile`);
   if(working.filter(n=>!RR.includes(n)).length!==3)issues.push(`${label(iso)}: domenica devono esserci esattamente 3 operativi`);
   return;
  }
  const rw=RR.filter(n=>works(w.schedule[n]?.[i]));
  const unavailable=RR.filter(n=>w.schedule[n]?.[i]==='RIPOSO'||PROTECTED.has(w.schedule[n]?.[i]));
  if(rw.length===3){const sh=rw.map(n=>w.schedule[n][i]);if(!['06:30-13:30','10:00-17:00','13:30-20:30'].every(s=>sh.includes(s)))issues.push(`${label(iso)}: i 3 responsabili devono fare 06:30-13:30, 10:00-17:00 e 13:30-20:30`)}
  else if(unavailable.length===1&&rw.length===2){const sh=rw.map(n=>w.schedule[n][i]);if(!(sh.includes('06:30-13:30')&&sh.includes('13:30-20:30')))issues.push(`${label(iso)}: con un responsabile assente/riposo, gli altri due devono fare 06:30-13:30 e 13:30-20:30`)}
  else if(rw.length<2)issues.push(`${label(iso)}: responsabili insufficienti per apertura e chiusura`);
 });
 return [...new Set(issues)];
}
function validateAdviceCurrent(w){
 const tips=[];if(!w?.dates||!w?.schedule)return tips;
 w.dates.forEach((iso,i)=>{
  const dow=new Date(iso+'T12:00:00').getDay();if(dow===0)return;
  const morning=[];
  if(!RR.some(n=>starts(w.schedule[n]?.[i],'06:30')))morning.push('responsabile alle 06:30');
  if(!every15('07:00','13:30',t=>cashActive(w,i,t).length>=1))morning.push('1 cassa');
  if(!every15('07:00','13:30',t=>effectiveSala(w,i,t).length>=2))morning.push('2 sala effettivi');
  if(!SALA.some(n=>starts(w.schedule[n]?.[i],'06:30')))morning.push('1 sala alle 06:30');
  if(!every15('07:00','13:30',t=>active(w,i,t).length>=4))morning.push('4 persone totali');
  if(morning.length)tips.push(`Controlla ${label(iso)}: mattina — ${morning.join(', ')}`);
  if([1,3,4].includes(dow)&&!every15('11:00','17:00',t=>active(w,i,t).length>=5))tips.push(`Controlla ${label(iso)}: verifica almeno 5 persone continuativamente 11:00-17:00`);
  const eve=[];
  if(!every15('17:00','20:30',t=>cashActive(w,i,t).length>=2))eve.push('2 casse');
  if(!every15('17:00','20:30',t=>active(w,i,t,n=>RR.includes(n)).length>=1))eve.push('1 responsabile');
  if(!every15('17:00','20:30',t=>effectiveSala(w,i,t).length>=1))eve.push('1 sala');
  if(!every15('17:00','20:30',t=>active(w,i,t).length>=4))eve.push('4 persone totali');
  if(eve.length)tips.push(`Controlla ${label(iso)}: 17:00-20:30 — ${eve.join(', ')}`);
  let closers=0;for(const n of Object.keys(w.schedule))if(at(w.schedule[n]?.[i],'20:29'))closers++;
  if(closers>4)tips.push(`${label(iso)}: chiusura in ${closers}; preferibile 4`);
  if(![1,3,4].includes(dow)&&!every15('13:30','17:00',t=>active(w,i,t).length>=4))tips.push(`${label(iso)}: preferibili almeno 4 persone 13:30-17:00`);
 });
 return [...new Set(tips)].slice(0,5);
}
function validateScheduleCurrent(data){
 const out=[];const weeks=Array.isArray(data?.weeks)?data.weeks:[];
 weeks.forEach((w,wi)=>validateWeekCurrent(w).forEach(message=>out.push({weekIndex:wi,message})));
 const timeline=new Map();
 weeks.forEach((w,wi)=>(w.dates||[]).forEach((d,i)=>{for(const n of Object.keys(w.schedule||{})){if(!timeline.has(n))timeline.set(n,[]);timeline.get(n).push({date:d,shift:w.schedule[n]?.[i],wi})}}));
 for(const [n,rows0] of timeline){const rows=rows0.sort((a,b)=>a.date.localeCompare(b.date));let streak=0,last=null;for(const row of rows){if(last){const gap=(new Date(row.date+'T12:00:00')-new Date(last+'T12:00:00'))/86400000;if(gap!==1)streak=0}if(works(row.shift)){streak++;if(streak>6){out.push({weekIndex:row.wi,message:`${n}: oltre 6 giorni consecutivi il ${row.date}`});streak=0}}else streak=0;last=row.date}}
 return out;
}
window.validateWeek=validateWeekCurrent;
window.validateWeekAdvice=validateAdviceCurrent;
window.validateScheduleCurrent=validateScheduleCurrent;
window.TM_CURRENT_RULES={RR,CASHIERS,CASH_BACKUP,SALA,OFF,works,spansOf};
})();