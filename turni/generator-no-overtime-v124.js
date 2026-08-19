(()=>{
'use strict';
const C=window.TM91,PREV=window.TM112;
if(!C||!PREV)return;
const RESP=[...C.RESPONSABILI],CASH=[...C.CASSA],FLOOR=['Giuliano','Manuel','Daniele','Paolo'],ALL=[...RESP,...CASH,...C.SALA];
const EPS=.001;
const works=s=>C.works(s),hrs=s=>C.hours(s),at=(s,t)=>C.at(s,t),isSplit=s=>C.spans(s).length>1;
const clone=x=>JSON.parse(JSON.stringify(x));
function overlapsAbs(w,a){return !!(a&&a.from&&a.to&&w.dates.some(d=>d>=a.from&&d<=a.to))}
function requestsInWeek(w,data){return (data?.constraints?.acceptedRequests||[]).filter(q=>q?.date&&w.dates.includes(q.date))}
function hasManualAbsence(w,data){return (data?.constraints?.absences||[]).some(a=>overlapsAbs(w,a))}
function fixedDates(w,data){const m={};for(const q of requestsInWeek(w,data)){if(!m[q.employee])m[q.employee]=new Set();m[q.employee].add(q.date)}return m}
function dayValid(w,d){
 const date=w.dates[d];
 if(C.isSunday(date)){
  const rr=RESP.filter(n=>works(w.schedule[n]?.[d])),cc=CASH.filter(n=>works(w.schedule[n]?.[d])),ff=FLOOR.filter(n=>works(w.schedule[n]?.[d]));
  return rr.length===1&&cc.length===1&&ff.length===2&&!works(w.schedule.Marco?.[d]);
 }
 const count=t=>ALL.reduce((z,n)=>z+(at(w.schedule[n]?.[d],t)?1:0),0),marco=works(w.schedule.Marco?.[d]),need=marco?5:4;
 if(count('07:00')!==4)return false;
 if(!RESP.some(n=>at(w.schedule[n]?.[d],'06:45'))||!FLOOR.some(n=>at(w.schedule[n]?.[d],'06:45')))return false;
 if(count('10:00')<5||count('13:30')<5||count('16:30')<5)return false;
 if(count('17:00')!==need||count('19:59')!==need||count('20:29')!==4)return false;
 if(!CASH.some(n=>at(w.schedule[n]?.[d],'07:00'))||!CASH.some(n=>at(w.schedule[n]?.[d],'13:30'))||!CASH.some(n=>at(w.schedule[n]?.[d],'20:29')))return false;
 return true;
}
function startsFor(n){
 if(RESP.includes(n))return ['06:30','07:00','08:00','09:00','10:00','11:00','11:30','12:00','12:30','13:00','13:30','14:00','15:00','16:00'];
 if(CASH.includes(n))return ['07:00','08:00','09:00','10:00','11:00','11:30','12:00','12:30','13:00','13:30','14:00','15:00','16:00'];
 if(FLOOR.includes(n))return ['06:30','07:00','08:00','09:00','10:00','11:00','11:30','12:00','12:30','13:00','13:30','14:00','15:00','16:00'];
 if(n==='Marco')return ['16:00','16:30'];
 return [];
}
function continuous(n,minH,maxH){
 const out=[];if(n==='Marco'){out.push('16:00-20:00','16:30-20:30');return out}
 const lo=Math.max(4,Math.ceil(minH*2-EPS)/2),hi=Math.min(n==='Giada'?8:10,Math.floor(maxH*2+EPS)/2);
 for(const st of startsFor(n)){const a=C.hm(st);for(let h=lo;h<=hi+EPS;h+=.5){const b=a+Math.round(h*60);if(b>C.hm('20:30'))continue;out.push(`${st}-${C.fmtHm(b)}`)}}
 return [...new Set(out)];
}
function optionScore(cur,s){return [(isSplit(s)?1:0),(s===cur?0:1),Math.abs(hrs(s)-hrs(cur))]}
function cmpScore(a,b){for(let i=0;i<a.length;i++){if(a[i]!==b[i])return a[i]-b[i]}return 0}
function validOptions(w,n,d,needSign){
 const cur=w.schedule[n]?.[d]||'RIPOSO',ch=hrs(cur),out=[cur];
 if(n==='Marco'){
  if(works(cur))out.push(...continuous(n,4,4));
  else if(needSign>0)out.push(...continuous(n,4,4));
 }else if(works(cur)){
  const min=needSign<0?Math.max(4,ch-5):Math.max(4,ch),max=needSign>0?Math.min(n==='Giada'?8:10,ch+5):ch;
  out.push(...continuous(n,min,max));
 }else if(needSign>0){
  out.push(...continuous(n,n==='Giada'?4:5,n==='Giada'?8:10));
 }
 const seen=new Set(),good=[];
 for(const s of out){if(seen.has(s))continue;seen.add(s);const dh=Math.round((hrs(s)-ch)*2);if(needSign>0&&dh<0)continue;if(needSign<0&&dh>0)continue;if(!needSign&&Math.abs(dh)>0)continue;
  const old=w.schedule[n][d];w.schedule[n][d]=s;const ok=dayValid(w,d);w.schedule[n][d]=old;if(ok)good.push({s,du:dh,score:optionScore(cur,s)});
 }
 return good.sort((a,b)=>cmpScore(a.score,b.score)).slice(0,32);
}
function balancePerson(w,n,fixed){
 const target=C.TARGET[n],current=C.weekHours(w,n),need=Math.round((target-current)*2);if(Math.abs(target-current)<EPS)return removeAvoidableSplits(w,n,fixed);
 const sign=Math.sign(need),days=[];
 for(let d=0;d<6;d++){if(fixed?.has(w.dates[d]))days.push([{s:w.schedule[n][d],du:0,score:[isSplit(w.schedule[n][d])?1:0,0,0]}]);else days.push(validOptions(w,n,d,sign))}
 let states=new Map([[0,{score:[0,0,0],plan:[]}]]);
 for(let d=0;d<6;d++){
  const next=new Map();for(const [sum,st] of states)for(const o of days[d]){const ns=sum+o.du;if(sign>0&&ns>need)continue;if(sign<0&&ns<need)continue;const sc=st.score.map((v,i)=>v+o.score[i]),prev=next.get(ns);if(!prev||cmpScore(sc,prev.score)<0)next.set(ns,{score:sc,plan:[...st.plan,o.s]})}
  states=next;if(!states.size)return false;
 }
 const best=states.get(need);if(!best)return false;for(let d=0;d<6;d++)w.schedule[n][d]=best.plan[d];return Math.abs(C.weekHours(w,n)-target)<EPS;
}
function removeAvoidableSplits(w,n,fixed){
 for(let d=0;d<6;d++){
  if(fixed?.has(w.dates[d]))continue;const cur=w.schedule[n][d];if(!isSplit(cur))continue;const h=hrs(cur),opts=continuous(n,h,h);for(const s of opts){const old=w.schedule[n][d];w.schedule[n][d]=s;if(dayValid(w,d)){break}w.schedule[n][d]=old}
 }
 return true;
}
function balanceRequestOnlyWeek(w,data){
 const fixed=fixedDates(w,data),before=clone(w.schedule),order=ALL.slice().sort((a,b)=>Math.abs(C.weekHours(w,b)-C.TARGET[b])-Math.abs(C.weekHours(w,a)-C.TARGET[a]));
 for(const n of order){if(!balancePerson(w,n,fixed[n])){w.schedule=before;throw new Error(`${n}: con le richieste accettate non riesco a mantenere ${C.TARGET[n]} ore senza straordinari.`)}}
 for(let d=0;d<7;d++)if(!dayValid(w,d)){w.schedule=before;throw new Error(`${C.dateLabel(w.dates[d])}: la compensazione delle richieste non mantiene una copertura valida.`)}
 for(const n of ALL)if(Math.abs(C.weekHours(w,n)-C.TARGET[n])>EPS){w.schedule=before;throw new Error(`${n}: ore non compensate dopo le richieste.`)}
 w.noOvertimeV124=true;w.smartMode='richieste-0-straordinari';w.v124Hours=Object.fromEntries(ALL.map(n=>[n,C.weekHours(w,n)]));w.v124Splits=Object.fromEntries(ALL.map(n=>[n,(w.schedule[n]||[]).filter(isSplit).length]));return w;
}
function generate(start){
 const data=PREV.generate(start);for(const w of data.weeks||[]){const req=requestsInWeek(w,data);if(req.length&&!hasManualAbsence(w,data))balanceRequestOnlyWeek(w,data)}
 data.generator='v124-no-overtime-requests';return data;
}
function validateSchedule(data){
 const out=PREV.validateSchedule(data);(data?.weeks||[]).forEach((w,wi)=>{if(!w.noOvertimeV124)return;for(const n of ALL){const h=C.weekHours(w,n),t=C.TARGET[n];if(Math.abs(h-t)>EPS)out.push({type:'ore',weekIndex:wi,date:null,employee:n,message:`${n}: con sole richieste deve restare a ${t}h, attuali ${h}h`})}});return out;
}
window.TM112={generate,validateSchedule};window.TM124={generate,validateSchedule};document.documentElement.dataset.turniGenerator='v124';
})();