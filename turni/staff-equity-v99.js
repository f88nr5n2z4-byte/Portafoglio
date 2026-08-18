(()=>{
'use strict';
const KEY='tm_v91_draft';
const C=window.TM91;if(!C)return;
const SALA=['Giuliano','Manuel','Daniele','Paolo'];
const CASSA=['Stefania B','Stefania F','Romina','Giada'];
const ALL=[...SALA,...CASSA];
const isOff=s=>!C.works(s);
function splitShift(kind,len){
 if(kind==='E')return len===8?'06:30-10:30 / 16:30-20:30':'06:30-10:30 / 17:00-20:00';
 if(kind==='M')return len===8?'10:00-14:00 / 16:30-20:30':'10:00-13:30 / 17:00-20:30';
 return len===8?'12:30-20:30':'13:30-20:30';
}
function fairPick(names,counter,offset=0){const min=Math.min(...names.map(n=>counter[n]||0));const tied=names.filter(n=>(counter[n]||0)===min);return tied[offset%tied.length]}
function rebalanceSala(data){
 const late=Object.fromEntries(SALA.map(n=>[n,0])),mid=Object.fromEntries(SALA.map(n=>[n,0])),early=Object.fromEntries(SALA.map(n=>[n,0]));
 data.weeks.forEach((w,wi)=>{
  const si=(w.dates||[]).findIndex(C.isSunday);const sundayWorkers=new Set(si>=0?SALA.filter(n=>C.works(w.schedule?.[n]?.[si])):[]);const len=n=>sundayWorkers.has(n)?7:8;
  for(let d=0;d<6;d++){
   const active=SALA.filter(n=>!isOff(w.schedule?.[n]?.[d]));if(active.length<3)continue;const marco=C.works(w.schedule?.Marco?.[d]);let remaining=[...active];
   if(!marco&&active.length===4){const l=fairPick(remaining,late,wi+d);late[l]++;w.schedule[l][d]=splitShift('L',len(l));remaining=remaining.filter(n=>n!==l)}
   const m=fairPick(remaining,mid,wi*6+d);mid[m]++;w.schedule[m][d]=splitShift('M',len(m));remaining=remaining.filter(n=>n!==m);
   remaining.sort((a,b)=>(early[a]||0)-(early[b]||0)||SALA.indexOf(a)-SALA.indexOf(b)).forEach(n=>{early[n]++;w.schedule[n][d]=splitShift('E',len(n))});
  }
 });
}
function cashSplit(original){
 const h=C.hours(original);if(!h)return original;
 const starts7=C.at(original,'07:00');const closes=C.through(original,'20:30');
 if(Math.abs(h-8)<.001){if(starts7)return'07:00-11:00 / 16:30-20:30';if(closes)return'10:00-14:00 / 16:30-20:30';return'10:00-14:00 / 16:30-20:30'}
 if(Math.abs(h-7)<.001){if(starts7)return'07:00-11:00 / 17:30-20:30';if(closes)return'10:00-14:00 / 17:30-20:30';return'10:00-14:00 / 17:30-20:30'}
 if(Math.abs(h-6)<.001){if(starts7)return'07:00-10:00 / 17:30-20:30';if(closes)return'10:00-13:00 / 17:30-20:30';return'10:00-13:00 / 17:30-20:30'}
 if(Math.abs(h-5)<.001){if(starts7)return'07:00-09:00 / 17:30-20:30';if(closes)return'10:00-12:00 / 17:30-20:30';return'10:00-12:00 / 17:30-20:30'}
 return original;
}
function splitCounts(data){const z=Object.fromEntries(ALL.map(n=>[n,0]));(data?.weeks||[]).forEach(w=>ALL.forEach(n=>(w.schedule?.[n]||[]).forEach(s=>{if(C.spans(s).length>1)z[n]++})));return z}
function rebalanceCassa(data){
 let counts=splitCounts(data);const salaMax=Math.max(...SALA.map(n=>counts[n]||0));const target=Math.max(0,salaMax-3);
 const candidates=[];data.weeks.forEach((w,wi)=>{for(let d=0;d<6;d++)CASSA.forEach((n,ni)=>{const s=w.schedule?.[n]?.[d];if(C.works(s)&&C.spans(s).length===1)candidates.push({w,wi,d,n,ni,s})})});
 let guard=0;while(guard++<200){counts=splitCounts(data);const n=[...CASSA].sort((a,b)=>(counts[a]||0)-(counts[b]||0)||CASSA.indexOf(a)-CASSA.indexOf(b))[0];if((counts[n]||0)>=target)break;const options=candidates.filter(x=>x.n===n&&C.spans(x.w.schedule[x.n][x.d]).length===1);if(!options.length)break;options.sort((a,b)=>((a.wi*6+a.d+n.length)%17)-((b.wi*6+b.d+n.length)%17));const x=options[0],next=cashSplit(x.w.schedule[x.n][x.d]);if(next===x.w.schedule[x.n][x.d]){candidates.splice(candidates.indexOf(x),1);continue}x.w.schedule[x.n][x.d]=next;
 }
}
function validateSundaySeven(data,out){
 const ft=[...C.RESPONSABILI,'Stefania B','Stefania F','Romina',...SALA];
 (data?.weeks||[]).forEach((w,wi)=>{const si=(w.dates||[]).findIndex(C.isSunday);if(si<0)return;ft.forEach(n=>{if(!C.works(w.schedule?.[n]?.[si]))return;for(let d=0;d<6;d++){const s=w.schedule?.[n]?.[d];if(C.works(s)&&Math.abs(C.hours(s)-7)>.001)out.push({type:'ore',weekIndex:wi,date:w.dates[d],employee:n,message:`${n}: lavorando domenica, ogni giorno feriale lavorato deve essere di 7h (qui ${C.hours(s)}h)`})}})});
}
function apply(data){if(!data?.weeks||data.weeks.length!==3)return data;rebalanceSala(data);rebalanceCassa(data);data.generator='v99-equity';data.staffSplitCounts=splitCounts(data);return data}
function runAfterGenerate(){setTimeout(()=>{try{const data=JSON.parse(localStorage.getItem(KEY)||'null');if(!data?.weeks?.length)return;const out=apply(data);const issues=C.validateSchedule(out);validateSundaySeven(out,issues);if(issues.length){console.warn('Staff equity v99: validazione fallita',issues);return}localStorage.setItem(KEY,JSON.stringify(out));sessionStorage.setItem('tm_staff_equity_v99','1');location.reload()}catch(e){console.error('Staff equity v99',e)}},80)}
document.addEventListener('click',e=>{if(e.target.closest('.v91gen'))runAfterGenerate()},true);
const base=C.validateSchedule.bind(C);
C.validateSchedule=function(data){const out=base(data);validateSundaySeven(data,out);const z=splitCounts(data),v=Object.values(z);if(v.length&&Math.max(...v)-Math.min(...v)>=5)out.push({type:'equita',weekIndex:-1,date:null,employee:null,message:`Cassa + Sala: differenza spezzati troppo alta (${ALL.map(n=>`${n} ${z[n]}`).join(', ')})`});return out};
window.validateScheduleCurrent=data=>C.validateSchedule(data);
})();