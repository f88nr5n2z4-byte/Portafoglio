(()=>{
'use strict';
const C=window.TM91;if(!C)return;
const KEY='tm_v91_draft';
const RESP=[...C.RESPONSABILI];
const CASH=[...C.CASSA];
const FLOOR=['Giuliano','Manuel','Daniele','Paolo'];
const ALL=[...RESP,...CASH,...C.SALA];
const TARGET=C.TARGET;
const TIMES=['06:45','07:00','10:00','13:30','16:30','17:00','19:59','20:29'];
const PAIRS=[['Giuliano','Manuel'],['Daniele','Paolo'],['Giuliano','Daniele'],['Manuel','Paolo'],['Giuliano','Paolo'],['Manuel','Daniele']];
const CANDS={
 'cassa-8':['07:00-15:00','09:00-17:00','12:30-20:30','07:00-11:00 / 16:30-20:30','10:00-14:00 / 16:30-20:30'],
 'cassa-7':['07:00-14:00','10:00-17:00','13:30-20:30','07:00-11:00 / 17:30-20:30','10:00-13:30 / 17:00-20:30'],
 'cassa-6':['07:00-13:00','11:00-17:00','14:30-20:30','07:00-10:00 / 17:30-20:30','10:00-13:00 / 17:00-20:00'],
 'cassa-5':['07:00-12:00','12:00-17:00','15:30-20:30','07:00-09:00 / 17:30-20:30','10:00-12:00 / 17:30-20:30'],
 'sala-8':['06:30-14:30','09:00-17:00','12:30-20:30','06:30-10:30 / 16:30-20:30','10:00-14:00 / 16:30-20:30'],
 'sala-7':['06:30-13:30','10:00-17:00','13:30-20:30','06:30-10:30 / 17:30-20:30','10:00-13:30 / 17:00-20:30']
};
const iso=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const mondayOf=s=>{const d=new Date(s+'T12:00:00'),k=(d.getDay()+6)%7;d.setDate(d.getDate()-k);return d};
const nextMonday=()=>{const d=new Date();d.setHours(12,0,0,0);const k=(8-d.getDay())%7||7;d.setDate(d.getDate()+k);return iso(d)};
const isSplit=s=>C.spans(s).length>1;
const present=(s,t)=>C.at(s,t);
const blankWeek=start=>{const dates=[];for(let i=0;i<7;i++){const d=new Date(start);d.setDate(start.getDate()+i);dates.push(iso(d))}const schedule={};ALL.forEach(n=>schedule[n]=Array(7).fill('RIPOSO'));return{dates,schedule,label:`${dates[0]} / ${dates[6]}`,period:'week',generator:'v112'}};
function phaseFor(monday){const base=new Date('2026-08-24T12:00:00');return Math.floor((monday-base)/(7*86400000))}
function rotatedRestMaps(k){
 const rr={},cr={},sr={};
 const respBase=[0,2,5],cashBase=[0,1,3,5],floorBase=[1,2,4,5];
 RESP.forEach((n,i)=>rr[n]=respBase[((i+k)%respBase.length+respBase.length)%respBase.length]);
 CASH.forEach((n,i)=>cr[n]=cashBase[((i+k)%cashBase.length+cashBase.length)%cashBase.length]);
 FLOOR.forEach((n,i)=>sr[n]=floorBase[((i+k)%floorBase.length+floorBase.length)%floorBase.length]);
 return{rr,cr,sr};
}
function setup(k){
 const sunResp=RESP[((k%3)+3)%3];
 const sunCash=CASH[((k%4)+4)%4];
 const sunFloor=PAIRS[((k%6)+6)%6];
 const len={};
 RESP.forEach(n=>len[n]=n===sunResp?7:8);
 CASH.forEach(n=>len[n]=n==='Giada'?(n===sunCash?5:6):(n===sunCash?7:8));
 FLOOR.forEach(n=>len[n]=sunFloor.includes(n)?7:8);
 const {rr,cr,sr}=rotatedRestMaps(k);
 const marcoDays=(k%2===0)?new Set([0,2,3,4]):new Set([0,2,3,5]);
 return{sunResp,sunCash,sunFloor,len,rr,cr,sr,marcoDays};
}
function respAssign(active,len,seed){
 const order=[...active].sort((a,b)=>(((RESP.indexOf(a)-seed)%3+3)%3)-(((RESP.indexOf(b)-seed)%3+3)%3));
 const roles=order.length===2?['open','close']:['open','mid','close'];
 const out={};
 order.forEach((n,i)=>{const tab=len[n]===7?{open:'06:30-13:30',mid:'10:00-17:00',close:'13:30-20:30'}:{open:'06:30-14:30',mid:'09:00-17:00',close:'12:30-20:30'};out[n]=tab[roles[i]]});
 return out;
}
function summary(assign){const z={};TIMES.forEach(t=>z[t]=Object.values(assign).reduce((s,x)=>s+(present(x,t)?1:0),0));return z}
function combos(names,len,role,splitCount){
 const lists=names.map(n=>CANDS[`${role}-${len[n]}`].filter(s=>!isSplit(s)||(splitCount[n]||0)<2));
 const out=[];
 function rec(i,a){
  if(i<names.length){for(const s of lists[i]){a[names[i]]=s;rec(i+1,a)}return}
  if(role==='cassa'){
   if(!names.some(n=>present(a[n],'07:00')))return;
   if(!names.some(n=>present(a[n],'13:30')))return;
   if(!names.some(n=>present(a[n],'20:29')))return;
  }else if(!names.some(n=>present(a[n],'06:45')))return;
  const copy={...a},inc={};names.forEach(n=>inc[n]=isSplit(copy[n])?1:0);out.push({a:copy,sm:summary(copy),inc});
 }
 rec(0,{});return out;
}
function solveDay(activeCash,activeFloor,len,respShifts,marcoWork,splitCount){
 const rsm=summary(respShifts),cc=combos(activeCash,len,'cassa',splitCount),ss=combos(activeFloor,len,'sala',splitCount),mopts=marcoWork?['16:00-20:00','16:30-20:30']:['RIPOSO'];
 let best=null;
 for(const ca of cc)for(const sa of ss)for(const ms of mopts){
  const total={};TIMES.forEach(t=>total[t]=rsm[t]+ca.sm[t]+sa.sm[t]+(present(ms,t)?1:0));
  if(total['10:00']<5||total['13:30']<5||total['16:30']<5)continue;
  if(marcoWork){if(total['17:00']!==5||total['19:59']!==5)continue}else if(total['17:00']!==4||total['19:59']!==4)continue;
  if(total['20:29']!==4)continue;
  const nc={...splitCount};[...CASH,...FLOOR].forEach(n=>{nc[n]=(nc[n]||0)+(ca.inc[n]||0)+(sa.inc[n]||0)});
  if([...CASH,...FLOOR].some(n=>nc[n]>2))continue;
  const tc=CASH.reduce((s,n)=>s+(nc[n]||0),0),ts=FLOOR.reduce((s,n)=>s+(nc[n]||0),0),vals=[...CASH,...FLOOR].map(n=>nc[n]||0),added=Object.values(ca.inc).reduce((a,b)=>a+b,0)+Object.values(sa.inc).reduce((a,b)=>a+b,0);
  const startsMorning=s=>{const p=C.spans(s);return p.length&&p[0][0]<810?1:0};
  const morningStarts=Object.values(respShifts).reduce((z,s)=>z+startsMorning(s),0)+Object.values(ca.a).reduce((z,s)=>z+startsMorning(s),0)+Object.values(sa.a).reduce((z,s)=>z+startsMorning(s),0)+(startsMorning(ms)?1:0);
  const coverage=(total['10:00']-5)+(total['13:30']-5)+(total['16:30']-5);
  const score=[Math.abs(morningStarts-6),coverage,Math.abs(tc-ts),Math.max(...vals)-Math.min(...vals),added,vals.reduce((a,b)=>a+b,0),vals.reduce((a,b)=>a+b*b,0)];
  if(!best||score.some((v,i)=>v<best.score[i]&&score.slice(0,i).every((x,j)=>x===best.score[j]))){best={score,assign:{...ca.a,...sa.a,Marco:ms},splitCount:nc}}
 }
 return best;
}
function generateWeek(start,k){
 const cfg=setup(k),w=blankWeek(start),splitCount=Object.fromEntries([...CASH,...FLOOR].map(n=>[n,0]));
 let sc=splitCount;
 for(let d=0;d<6;d++){
  const ar=RESP.filter(n=>cfg.rr[n]!==d),ac=CASH.filter(n=>cfg.cr[n]!==d),af=FLOOR.filter(n=>cfg.sr[n]!==d),rsh=respAssign(ar,cfg.len,d+k),best=solveDay(ac,af,cfg.len,rsh,cfg.marcoDays.has(d),sc);
  if(!best)throw new Error(`Nessuna soluzione valida per ${C.dateLabel(w.dates[d])}`);
  Object.entries(rsh).forEach(([n,s])=>w.schedule[n][d]=s);Object.entries(best.assign).forEach(([n,s])=>w.schedule[n][d]=s);sc=best.splitCount;
 }
 RESP.forEach(n=>w.schedule[n][6]=n===cfg.sunResp?'08:00-13:00':'RIPOSO');
 CASH.forEach(n=>w.schedule[n][6]=n===cfg.sunCash?'08:00-13:00':'RIPOSO');
 FLOOR.forEach(n=>w.schedule[n][6]=cfg.sunFloor.includes(n)?'08:00-13:00':'RIPOSO');w.schedule.Marco[6]='RIPOSO';
 w.splitCounts=sc;return w;
}
function generate(startIso){const m=mondayOf(startIso),phase=phaseFor(m),weeks=[];for(let wi=0;wi<3;wi++){const s=new Date(m);s.setDate(m.getDate()+wi*7);weeks.push(generateWeek(s,phase+wi))}return{weeks,generator:'v112',updated:new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date())}}
function add(out,type,wi,date,employee,message){out.push({type,weekIndex:wi,date,employee,message})}
function countAt(w,d,t){return ALL.reduce((z,n)=>z+(present(w.schedule[n]?.[d],t)?1:0),0)}
function validateWeek(w,wi=0){
 const out=[];
 ALL.forEach(n=>{const h=C.weekHours(w,n),t=TARGET[n];if(Math.abs(h-t)>.001)add(out,'ore',wi,null,n,`${n}: ${h}h invece di ${t}h (straordinari o ore mancanti non consentiti)`)});
 const split=Object.fromEntries([...CASH,...FLOOR].map(n=>[n,(w.schedule[n]||[]).filter(isSplit).length]));
 [...CASH,...FLOOR].forEach(n=>{if(split[n]>2)add(out,'spezzati',wi,null,n,`${n}: ${split[n]} spezzati nella settimana, massimo 2`)});
 const ctot=CASH.reduce((s,n)=>s+split[n],0),stot=FLOOR.reduce((s,n)=>s+split[n],0);if(Math.abs(ctot-stot)>1)add(out,'spezzati',wi,null,null,`Spezzati non equilibrati tra Cassa (${ctot}) e Sala (${stot})`);
 const vals=Object.values(split);if(Math.max(...vals)-Math.min(...vals)>1)add(out,'spezzati',wi,null,null,'Spezzati non distribuiti equamente tra le persone');
 w.dates.forEach((date,d)=>{
  const lab=C.dateLabel(date),sun=C.isSunday(date);
  if(sun){const rr=RESP.filter(n=>C.works(w.schedule[n]?.[d])),cc=CASH.filter(n=>C.works(w.schedule[n]?.[d])),ff=FLOOR.filter(n=>C.works(w.schedule[n]?.[d]));if(rr.length!==1)add(out,'domenica',wi,date,null,`${lab}: deve lavorare 1 Responsabile`);if(cc.length!==1)add(out,'domenica',wi,date,null,`${lab}: deve lavorare 1 Cassa`);if(ff.length!==2)add(out,'domenica',wi,date,null,`${lab}: devono lavorare 2 Sala`);[...rr,...cc,...ff].forEach(n=>{if(w.schedule[n][d]!=='08:00-13:00')add(out,'domenica',wi,date,n,`${lab}: ${n} deve fare 08:00-13:00`)});if(C.works(w.schedule.Marco?.[d]))add(out,'marco',wi,date,'Marco',`${lab}: Marco deve riposare`);return}
  const rr630=RESP.filter(n=>present(w.schedule[n]?.[d],'06:45')).length,fl630=FLOOR.filter(n=>present(w.schedule[n]?.[d],'06:45')).length;if(rr630<1||fl630<1)add(out,'apertura',wi,date,null,`${lab}: prima delle 07:00 servono almeno 1 Responsabile + 1 Sala`);
  if(!CASH.some(n=>present(w.schedule[n]?.[d],'07:00')))add(out,'cassa',wi,date,null,`${lab}: manca una Cassa alle 07:00`);
  if(!CASH.some(n=>present(w.schedule[n]?.[d],'13:30')))add(out,'cassa',wi,date,null,`${lab}: manca una Cassa alle 13:30`);
  if(!CASH.some(n=>present(w.schedule[n]?.[d],'20:29')))add(out,'cassa',wi,date,null,`${lab}: manca una Cassa alle 20:30`);
  for(const t of ['10:00','13:30','16:30']){const c=countAt(w,d,t);if(c<5)add(out,'copertura',wi,date,null,`${lab}: alle ${t} servono almeno 5 persone totali`)}
  const marco=C.works(w.schedule.Marco?.[d]),need=marco?5:4;if(countAt(w,d,'17:00')!==need)add(out,'copertura',wi,date,null,`${lab}: alle 17:00 devono esserci ${need} persone${marco?' (4 + Marco)':''}`);if(countAt(w,d,'19:59')!==need)add(out,'copertura',wi,date,null,`${lab}: alle 20:00 devono esserci ${need} persone${marco?' (4 + Marco)':''}`);if(countAt(w,d,'20:29')!==4)add(out,'chiusura',wi,date,null,`${lab}: in chiusura devono esserci esattamente 4 persone totali`);
 });
 [...RESP,...CASH,...FLOOR].forEach(n=>{const rests=w.dates.slice(0,6).filter((_,d)=>w.schedule[n]?.[d]==='RIPOSO').length;if(rests!==1)add(out,'riposi',wi,null,n,`${n}: deve avere esattamente 1 riposo infrasettimanale`)});
 const mh=C.weekHours(w,'Marco'),mw=(w.schedule.Marco||[]).filter(C.works).length;if(Math.abs(mh-16)>.001)add(out,'marco',wi,null,'Marco',`Marco: ${mh}h invece di 16h`);if(mw!==4)add(out,'marco',wi,null,'Marco',`Marco deve lavorare esattamente 4 giorni da 4h`);(w.schedule.Marco||[]).forEach((s,d)=>{if(!C.works(s))return;if(Math.abs(C.hours(s)-4)>.001)add(out,'marco',wi,w.dates[d],'Marco',`${C.dateLabel(w.dates[d])}: Marco deve fare 4h`)});
 const si=w.dates.findIndex(C.isSunday);if(si>=0){[...RESP,...CASH.filter(n=>n!=='Giada'),...FLOOR].forEach(n=>{if(!C.works(w.schedule[n]?.[si]))return;for(let d=0;d<6;d++)if(C.works(w.schedule[n]?.[d])&&Math.abs(C.hours(w.schedule[n][d])-7)>.001)add(out,'ore',wi,w.dates[d],n,`${n}: lavorando domenica deve fare 7h nei feriali`)});}
 return out;
}
function validateSchedule(data){const out=[];(data?.weeks||[]).forEach((w,i)=>out.push(...validateWeek(w,i)));return out}
C.validateWeek=validateWeek;C.validateSchedule=validateSchedule;window.validateWeek=w=>validateWeek(w,0).map(x=>x.message);window.validateScheduleCurrent=validateSchedule;
window.TM112={generate,validateSchedule};
document.addEventListener('click',e=>{const b=e.target.closest('.v91gen');if(!b)return;e.preventDefault();e.stopPropagation();e.stopImmediatePropagation();try{const start=document.getElementById('v91Start')?.value||nextMonday(),draft=generate(start),errors=validateSchedule(draft);if(errors.length){console.error('v112 generation errors',errors);alert(`Generazione bloccata: ${errors.length} errori. Riprova.`);return}localStorage.setItem(KEY,JSON.stringify(draft));location.reload()}catch(err){console.error(err);alert('Errore nella generazione: '+err.message)}},true);
})();