(()=>{
'use strict';
const KEY='tm_v91_draft';
const FT=['Giuliano','Manuel','Daniele','Paolo'];
const C=window.TM91;if(!C)return;
const isOff=s=>!C.works(s);
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
function rebalance(data){
 if(!data?.weeks||data.weeks.length!==3)return data;
 const late=Object.fromEntries(FT.map(n=>[n,0]));
 const mid=Object.fromEntries(FT.map(n=>[n,0]));
 const early=Object.fromEntries(FT.map(n=>[n,0]));
 data.weeks.forEach((w,wi)=>{
  const sunIndex=(w.dates||[]).findIndex(C.isSunday);
  const sundayWorkers=new Set(sunIndex>=0?FT.filter(n=>C.works(w.schedule?.[n]?.[sunIndex])):[]);
  const len=n=>sundayWorkers.has(n)?7:8;
  for(let d=0;d<6;d++){
   const active=FT.filter(n=>!isOff(w.schedule?.[n]?.[d]));
   if(active.length<3)continue;
   const marco=C.works(w.schedule?.Marco?.[d]);
   let remaining=[...active];
   if(!marco&&active.length===4){
    const l=fairPick(remaining,late,wi+d);late[l]++;w.schedule[l][d]=splitShift('L',len(l));remaining=remaining.filter(n=>n!==l);
   }
   const m=fairPick(remaining,mid,wi*6+d);mid[m]++;w.schedule[m][d]=splitShift('M',len(m));remaining=remaining.filter(n=>n!==m);
   remaining.sort((a,b)=>(early[a]||0)-(early[b]||0)||FT.indexOf(a)-FT.indexOf(b)).forEach(n=>{early[n]++;w.schedule[n][d]=splitShift('E',len(n))});
  }
 });
 data.generator='v97-equity';
 data.salaEquity={late,mid,early};
 return data;
}
function splitCounts(data){const z=Object.fromEntries(FT.map(n=>[n,0]));(data?.weeks||[]).forEach(w=>FT.forEach(n=>(w.schedule?.[n]||[]).forEach(s=>{if(C.spans(s).length>1)z[n]++})));return z}
function runAfterGenerate(){setTimeout(()=>{try{const data=JSON.parse(localStorage.getItem(KEY)||'null');if(!data?.weeks?.length)return;const out=rebalance(data);const issues=C.validateSchedule(out);if(issues.length){console.warn('Sala equity v97: validazione fallita',issues);return}localStorage.setItem(KEY,JSON.stringify(out));sessionStorage.setItem('tm_sala_equity_v97','1');location.reload()}catch(e){console.error('Sala equity v97',e)}},80)}
document.addEventListener('click',e=>{if(e.target.closest('.v91gen'))runAfterGenerate()},true);
const base=C.validateSchedule.bind(C);
C.validateSchedule=function(data){const out=base(data);const z=splitCounts(data),v=Object.values(z);if(v.length&&Math.max(...v)-Math.min(...v)>1)out.push({type:'equita',weekIndex:-1,date:null,employee:null,message:`Sala: spezzati non equilibrati (${FT.map(n=>`${n} ${z[n]}`).join(', ')})`});return out};
window.validateScheduleCurrent=data=>C.validateSchedule(data);
})();