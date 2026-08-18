(()=>{
'use strict';
const RR=['Umberto','Fabio','Emanuele'];
const CC=['Stefania B','Giada','Romina','Stefania F'];
const BB=['Giuliano','Daniele','Manuel'];
const SS=['Giuliano','Daniele','Manuel','Paolo','Marco'];
const OFF2=new Set(['RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—']);
const spans2=s=>{if(!s||OFF2.has(s))return[];return String(s).split('/').map(x=>x.trim()).map(x=>{const p=x.split('-').map(v=>hm(v.trim()));return p.length===2&&Number.isFinite(p[0])&&Number.isFinite(p[1])&&p[1]>p[0]?p:null}).filter(Boolean)};
const work2=s=>spans2(s).length>0;
const at2=(s,t)=>{const x=hm(t);return spans2(s).some(([a,b])=>a<=x&&x<b)};
const start2=(s,t)=>{const x=hm(t);return spans2(s).some(([a])=>a===x)};
function eachQuarter(a,b,fn){for(let t=hm(a);t<hm(b);t+=15){const x=String(Math.floor(t/60)).padStart(2,'0')+':'+String(t%60).padStart(2,'0');if(!fn(x))return false}return true}
function activeAt(w,i,t,pred=()=>true){return Object.keys(w.schedule||{}).filter(n=>pred(n)&&at2(w.schedule[n]?.[i],t))}
function cashAt2(w,i,t){return activeAt(w,i,t,n=>CC.includes(n)||BB.includes(n))}
function effectiveSalaAt(w,i,t){
 const dedicated=activeAt(w,i,t,n=>CC.includes(n));
 const backups=dedicated.length?[]:activeAt(w,i,t,n=>BB.includes(n)).slice(0,1);
 return activeAt(w,i,t,n=>SS.includes(n)&&!backups.includes(n));
}
function continuousCount(w,i,a,b,pred,need){return eachQuarter(a,b,t=>activeAt(w,i,t,pred).length>=need)}
function continuousCash(w,i,a,b,need){return eachQuarter(a,b,t=>cashAt2(w,i,t).length>=need)}
function continuousEffectiveSala(w,i,a,b,need){return eachQuarter(a,b,t=>effectiveSalaAt(w,i,t).length>=need)}
function morningProblems(w,i){
 const miss=[];
 if(!RR.some(n=>start2(w.schedule[n]?.[i],'06:30')))miss.push('responsabile alle 06:30');
 if(!continuousCash(w,i,'07:00','13:30',1))miss.push('1 cassa');
 if(!continuousEffectiveSala(w,i,'07:00','13:30',2))miss.push('2 sala effettivi');
 if(!SS.some(n=>start2(w.schedule[n]?.[i],'06:30')))miss.push('1 sala alle 06:30');
 if(!continuousCount(w,i,'07:00','13:30',()=>true,4))miss.push('4 persone totali');
 return miss;
}
window.validateWeek=function(w){
 const issues=[];if(!w?.dates||!w?.schedule)return issues;
 w.dates.forEach((iso,i)=>{
  const dow=new Date(iso+'T12:00:00').getDay(),label=fmtDate(iso),working=Object.keys(w.schedule).filter(n=>work2(w.schedule[n]?.[i]));
  if(dow===0){
   if(working.length!==4)issues.push(`${label}: domenica ${working.length} persone invece di 4`);
   if(working.some(n=>w.schedule[n]?.[i]!=='08:00-13:00'))issues.push(`${label}: la domenica chi lavora deve fare 08:00-13:00`);
   if(working.filter(n=>RR.includes(n)).length!==1)issues.push(`${label}: domenica deve esserci esattamente 1 responsabile`);
   if(working.filter(n=>!RR.includes(n)).length!==3)issues.push(`${label}: domenica devono esserci esattamente 3 operativi`);
   return;
  }
  const rw=RR.filter(n=>work2(w.schedule[n]?.[i])),resting=RR.filter(n=>w.schedule[n]?.[i]==='RIPOSO');
  if(rw.length===3){const sh=rw.map(n=>w.schedule[n][i]);for(const s of ['06:30-13:30','10:00-17:00','13:30-20:30'])if(!sh.includes(s))issues.push(`${label}: i 3 responsabili devono fare 06:30-13:30, 10:00-17:00 e 13:30-20:30`)}
  else if(resting.length===1&&rw.length===2){const sh=rw.map(n=>w.schedule[n][i]);if(!(sh.includes('06:30-13:30')&&sh.includes('13:30-20:30')))issues.push(`${label}: con ${resting[0]} a RIPOSO, gli altri due responsabili devono fare 06:30-13:30 e 13:30-20:30`)}
  else if(rw.length<2)issues.push(`${label}: responsabili insufficienti per apertura e chiusura`);
  const morning=morningProblems(w,i);if(morning.length)issues.push(`${label}: copertura mattina insufficiente — manca ${morning.join(', ')}`);
  if([1,3,4].includes(dow)&&!continuousCount(w,i,'11:00','17:00',()=>true,5))issues.push(`${label}: lunedì/mercoledì/giovedì servono almeno 5 persone continuativamente dalle 11:00 alle 17:00`);
  const eve=[];
  if(!continuousCash(w,i,'17:00','20:30',2))eve.push('2 casse');
  if(!continuousCount(w,i,'17:00','20:30',n=>RR.includes(n),1))eve.push('1 responsabile');
  if(!continuousEffectiveSala(w,i,'17:00','20:30',1))eve.push('1 sala effettivo');
  if(!continuousCount(w,i,'17:00','20:30',()=>true,4))eve.push('4 persone totali');
  if(eve.length)issues.push(`${label}: copertura 17:00-20:30 insufficiente — manca ${eve.join(', ')}`);
 });
 for(const n of Object.keys(w.schedule||{})){let streak=0;for(let i=0;i<w.dates.length;i++){if(work2(w.schedule[n]?.[i])){streak++;if(streak>6){issues.push(`${n}: oltre 6 giorni consecutivi il ${w.dates[i]}`);break}}else streak=0}}
 return [...new Set(issues)];
};
window.validateWeekAdvice=function(w){
 const tips=[];if(!w?.dates||!w?.schedule)return tips;
 w.dates.forEach((iso,i)=>{const dow=new Date(iso+'T12:00:00').getDay();if(dow===0)return;const label=fmtDate(iso);let c2030=0;for(const n of Object.keys(w.schedule))if(at2(w.schedule[n]?.[i],'20:29'))c2030++;if(c2030>4)tips.push(`${label}: chiusura in ${c2030}; meglio 4, facendo eventualmente uscire qualcuno alle 20:00 e recuperando 30 minuti in un altro giorno`);if(![1,3,4].includes(dow)&&!continuousCount(w,i,'13:30','17:00',()=>true,4))tips.push(`${label}: sarebbe preferibile avere almeno 4 persone nella fascia 13:30-17:00`)});
 const marco=w.schedule.Marco||[];if(marco.length===7){const h=marco.reduce((z,s)=>z+spans2(s).reduce((a,[x,y])=>a+(y-x)/60,0),0);if(h>17)tips.push(`Marco: ${h}h nella settimana; obiettivo circa 16h, poco più solo se serve`)}
 return [...new Set(tips)].slice(0,5);
};
})();