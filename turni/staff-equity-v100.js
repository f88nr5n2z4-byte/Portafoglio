(()=>{
'use strict';
const KEY='tm_v91_draft';
const C=window.TM91;if(!C)return;
const SALA=['Giuliano','Manuel','Daniele','Paolo'];
const FT_SUNDAY=[...C.RESPONSABILI,'Stefania B','Stefania F','Romina',...SALA];
function splitShift(kind,len){
 if(kind==='E')return len===8?'06:30-10:30 / 16:30-20:30':'06:30-10:30 / 17:00-20:00';
 if(kind==='M')return len===8?'10:00-14:00 / 16:30-20:30':'10:00-13:30 / 17:00-20:30';
 return len===8?'12:30-20:30':'13:30-20:30';
}
function fairPick(names,counter,offset=0){
 const min=Math.min(...names.map(n=>counter[n]||0));
 const tied=names.filter(n=>(counter[n]||0)===min);
 return tied[offset%tied.length];
}
function rebalanceSala(data){
 const late=Object.fromEntries(SALA.map(n=>[n,0]));
 const mid=Object.fromEntries(SALA.map(n=>[n,0]));
 const early=Object.fromEntries(SALA.map(n=>[n,0]));
 (data?.weeks||[]).forEach((w,wi)=>{
  const si=(w.dates||[]).findIndex(C.isSunday);
  const sundayWorkers=new Set(si>=0?SALA.filter(n=>C.works(w.schedule?.[n]?.[si])):[]);
  const len=n=>sundayWorkers.has(n)?7:8;
  for(let d=0;d<6;d++){
   const active=SALA.filter(n=>C.works(w.schedule?.[n]?.[d]));
   if(active.length<3)continue;
   const marco=C.works(w.schedule?.Marco?.[d]);
   let remaining=[...active];
   if(!marco&&active.length===4){
    const continuous=fairPick(remaining,late,wi*6+d);
    late[continuous]++;
    w.schedule[continuous][d]=splitShift('L',len(continuous));
    remaining=remaining.filter(n=>n!==continuous);
   }
   const central=fairPick(remaining,mid,wi*6+d);
   mid[central]++;
   w.schedule[central][d]=splitShift('M',len(central));
   remaining=remaining.filter(n=>n!==central);
   remaining.sort((a,b)=>(early[a]||0)-(early[b]||0)||SALA.indexOf(a)-SALA.indexOf(b));
   remaining.forEach(n=>{early[n]++;w.schedule[n][d]=splitShift('E',len(n))});
  }
 });
}
function splitCounts(data){
 const z=Object.fromEntries(SALA.map(n=>[n,0]));
 (data?.weeks||[]).forEach(w=>SALA.forEach(n=>(w.schedule?.[n]||[]).forEach(s=>{if(C.spans(s).length>1)z[n]++})));
 return z;
}
function validateSundaySeven(data,out){
 (data?.weeks||[]).forEach((w,wi)=>{
  const si=(w.dates||[]).findIndex(C.isSunday);if(si<0)return;
  FT_SUNDAY.forEach(n=>{
   if(!C.works(w.schedule?.[n]?.[si]))return;
   let weekdayWorked=0;
   for(let d=0;d<6;d++){
    const s=w.schedule?.[n]?.[d];
    if(!C.works(s))continue;
    weekdayWorked++;
    const h=C.hours(s);
    if(Math.abs(h-7)>.001)out.push({type:'ore',weekIndex:wi,date:w.dates[d],employee:n,message:`${n}: lavora domenica, quindi il turno feriale deve essere di 7h esatte (qui ${h}h)`});
   }
   if(weekdayWorked!==5)out.push({type:'ore',weekIndex:wi,date:null,employee:n,message:`${n}: lavorando domenica deve lavorare 5 giorni feriali da 7h + domenica 5h`});
   const sh=C.hours(w.schedule[n][si]);
   if(Math.abs(sh-5)>.001)out.push({type:'ore',weekIndex:wi,date:w.dates[si],employee:n,message:`${n}: la domenica deve essere di 5h esatte`});
  });
 }
function validateSplitEquity(data,out){
 const z=splitCounts(data),vals=Object.values(z);
 if(!vals.length)return;
 const diff=Math.max(...vals)-Math.min(...vals);
 if(diff>=5)out.push({type:'equita',weekIndex:-1,date:null,employee:null,message:`Sala: differenza spezzati troppo alta (${SALA.map(n=>`${n} ${z[n]}`).join(', ')}). È errore solo da 5 di differenza in su.`});
}
function apply(data){if(!data?.weeks||data.weeks.length!==3)return data;rebalanceSala(data);data.generator='v100-equity';data.salaSplitCounts=splitCounts(data);return data}
function runAfterGenerate(){setTimeout(()=>{try{const data=JSON.parse(localStorage.getItem(KEY)||'null');if(!data?.weeks?.length)return;const out=apply(data);const issues=[];validateSundaySeven(out,issues);validateSplitEquity(out,issues);if(issues.length){console.warn('Staff equity v100: validazione specifica fallita',issues);return}localStorage.setItem(KEY,JSON.stringify(out));sessionStorage.setItem('tm_staff_equity_v100','1');location.reload()}catch(e){console.error('Staff equity v100',e)}},80)}
document.addEventListener('click',e=>{if(e.target.closest('.v91gen'))runAfterGenerate()},true);
const base=C.validateSchedule.bind(C);
C.validateSchedule=function(data){const out=base(data);validateSundaySeven(data,out);validateSplitEquity(data,out);return out};
window.validateScheduleCurrent=data=>C.validateSchedule(data);
})();