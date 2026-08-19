(()=>{
'use strict';
const C=window.TM91,PREV=window.TM112;
if(!C||!PREV)return;
const ABS_KEY='tm_v121_absences',REQ_KEY='tm_v121_requests';
const RESP=[...C.RESPONSABILI],CASH=[...C.CASSA],FLOOR=['Giuliano','Manuel','Daniele','Paolo'],ALL=[...RESP,...CASH,...C.SALA];
const TIMES=['06:45','07:00','10:00','13:30','16:30','17:00','19:59','20:29'];
const MONTHS={gen:0,feb:1,mar:2,apr:3,mag:4,giu:5,lug:6,ago:7,set:8,ott:9,nov:10,dic:11};
const OFF=new Set(['RIPOSO','FERIE','PERMESSO','MALATTIA','MATERNITÀ','—','']);
const isSplit=s=>C.spans(s).length>1, works=s=>C.works(s), hrs=s=>C.hours(s), at=(s,t)=>C.at(s,t);
const clone=x=>JSON.parse(JSON.stringify(x));
function load(k){try{const x=JSON.parse(localStorage.getItem(k)||'[]');return Array.isArray(x)?x:[]}catch{return[]}}
function saveRaw(k,v){localStorage.setItem(k,JSON.stringify(v))}
function role(n){return RESP.includes(n)?'resp':CASH.includes(n)?'cash':FLOOR.includes(n)?'floor':n==='Marco'?'marco':''}
function isoDateFromLabel(label,created){
 const m=String(label||'').toLowerCase().match(/(?:lun|mar|mer|gio|ven|sab|dom)?\s*(\d{1,2})\s+([a-zà]+)/i);
 if(!m)return null;const mon=MONTHS[m[2].slice(0,3)];if(mon===undefined)return null;
 const base=created?new Date(created):new Date(),years=[base.getFullYear()-1,base.getFullYear(),base.getFullYear()+1];
 let best=null,diff=Infinity;for(const y of years){const d=new Date(y,mon,+m[1],12),q=Math.abs(d-base);if(q<diff){best=d;diff=q}}
 if(!best)return null;return `${best.getFullYear()}-${String(best.getMonth()+1).padStart(2,'0')}-${String(best.getDate()).padStart(2,'0')}`;
}
function accepted(){
 const out=[];for(const x of load(REQ_KEY)){
  if(x.status!=='ACCETTATA')continue;
  const m=String(x.message||''),g=m.match(/Giorno:\s*([^\n]+).*?Turno richiesto:\s*([^\n]+)/s);if(!g)continue;
  const date=isoDateFromLabel(g[1].trim(),x.created_at),wanted=g[2].trim();
  if(date&&ALL.includes(x.employee))out.push({employee:x.employee,date,wanted,source:'request',id:x.id});
 }
 return out;
}
function absences(){
 const out=[];for(const x of load(ABS_KEY)){
  if(!ALL.includes(x.employee)||!x.from||!x.to)continue;
  out.push({employee:x.employee,from:x.from,to:x.to,wanted:String(x.type||'FERIE').toUpperCase(),source:'manual'});
 }
 return out;
}
function absentValue(v){return OFF.has(String(v||'').toUpperCase())}
function wantedOn(n,date,acc,abs){
 const a=abs.find(x=>x.employee===n&&date>=x.from&&date<=x.to);if(a)return a.wanted;
 const q=acc.filter(x=>x.employee===n&&x.date===date);return q.length?q[q.length-1].wanted:null;
}
function weekConstraints(w,acc,abs){
 const entries=[];
 for(const n of ALL)for(const date of w.dates){const v=wantedOn(n,date,acc,abs);if(v)entries.push({employee:n,date,wanted:v})}
 return entries;
}
function sundayWorkers(w){
 const si=w.dates.findIndex(C.isSunday),set=new Set();
 if(si<0)return set;for(const n of ALL)if(works(w.schedule[n]?.[si]))set.add(n);return set;
}
function continuousPool(n,minH,maxH,exact=false){
 const r=role(n),starts=r==='floor'?['06:30','07:00','07:30','08:00','09:00','10:00','11:00','11:30','12:00','12:30','13:00','13:30','14:00']:
 r==='cash'?['07:00','07:30','08:00','09:00','10:00','11:00','11:30','12:00','12:30','13:00','13:30','14:00']:
 r==='resp'?['06:30','07:00','09:00','10:00','11:00','11:30','12:00','12:30','13:00','13:30']:[];
 const out=[];
 for(const st of starts){const a=C.hm(st);for(let h=Math.ceil(minH*2)/2;h<=maxH+1e-9;h+=.5){if(exact&&Math.abs(h-minH)>.001)continue;const b=a+Math.round(h*60);if(b>C.hm('20:30'))continue;out.push(`${st}-${C.fmtHm(b)}`)}}
 for(const s of C.QUICK||[]){if(!works(s)||isSplit(s))continue;const h=hrs(s);if(h+1e-9<minH||h-1e-9>maxH)continue;if(exact&&Math.abs(h-minH)>.001)continue;if(r==='cash'&&C.spans(s)[0]?.[0]<C.hm('07:00'))continue;if(r==='floor'&&C.spans(s)[0]?.[0]<C.hm('06:30'))continue;out.push(s)}
 return [...new Set(out)];
}
function optsFor(n,base,{allowSplit=false,addedDay=false,fixed=null,respShortage=false,normal=false,splitUsed=0,totalSplit=0}={}){
 if(fixed&&!absentValue(fixed))return [fixed];
 if(n==='Marco')return [base];
 const r=role(n),bh=hrs(base);
 if(normal){
  if(r==='resp')return [base];
  return continuousPool(n,bh,bh,true);
 }
 if(r==='resp'&&!respShortage&&!addedDay)return [base];
 let minH=addedDay?(n==='Giada'?5:6.5):Math.max(5,bh);
 let maxH=addedDay?(n==='Giada'?6.5:9.5):(n==='Giada'?Math.max(bh,7):Math.max(bh,10));
 let pool=continuousPool(n,minH,maxH,false);
 if(works(base)&&!isSplit(base))pool.unshift(base);
 if(allowSplit&&r!=='resp'&&splitUsed<1&&totalSplit<5){
  pool.push('07:00-13:00 / 17:00-20:00','07:00-13:00 / 17:00-20:30');
 }
 if(allowSplit&&r==='resp'&&respShortage&&splitUsed<1&&totalSplit<5)pool.push('06:30-13:30 / 17:00-20:30');
 return [...new Set(pool)].filter(works);
}
function sig(s){return TIMES.map(t=>at(s,t)?1:0)}
function lex(a,b){for(let i=0;i<a.length;i++){if(a[i]<b[i])return-1;if(a[i]>b[i])return 1}return 0}
function solveDay(w,d,active,fixedMap,ctx){
 const marco=active.includes('Marco'),exact17=marco?5:4;
 let states=[{cnt:Array(8).fill(0),flags:Array(5).fill(0),cost:[0,0,0,0,0],a:{},spl:0,extra:{}}];
 for(const n of active){
  const next=new Map(),base=w.schedule[n][d],addedDay=!works(base),opts=optsFor(n,base,{allowSplit:ctx.allowSplit,addedDay,fixed:fixedMap[n],respShortage:ctx.respShortage,normal:ctx.normal,splitUsed:ctx.priorSplit[n]||0,totalSplit:ctx.totalSplit});
  if(!opts.length)return null;
  for(const st of states)for(const s of opts){
   const v=sig(s),cnt=st.cnt.map((x,i)=>x+v[i]);
   if(cnt[1]>4||cnt[5]>exact17||cnt[6]>exact17||cnt[7]>4)continue;
   const f=[...st.flags];
   if(CASH.includes(n)){if(v[1])f[0]=1;if(v[3])f[1]=1;if(v[7])f[2]=1}
   if(RESP.includes(n)&&v[0])f[3]=1;if(FLOOR.includes(n)&&v[0])f[4]=1;
   const sp=isSplit(s)?1:0;if(ctx.totalSplit+st.spl+sp>5)continue;
   const targetBase=addedDay?0:hrs(base),ex=n==='Marco'?0:Math.max(0,hrs(s)-targetBase),old=ctx.priorOT[n]||0;
   const protectResp=(RESP.includes(n)&&!ctx.respShortage?ex*5000:0),protectGiada=n==='Giada'?ex*300:0;
   const fair=(old+ex)*(old+ex)-old*old;
   const change=(s===base?0:1);
   const cost=[st.cost[0]+sp,st.cost[1]+protectResp+protectGiada,st.cost[2]+fair,st.cost[3]+ex,st.cost[4]+change];
   const a={...st.a,[n]:s},extra={...st.extra,[n]:(st.extra[n]||0)+ex};
   const cap=cnt.map((x,i)=>[2,3,4].includes(i)?Math.min(5,x):x),key=cap.join(',')+'|'+f.join(',');
   const prev=next.get(key);if(!prev||lex(cost,prev.cost)<0)next.set(key,{cnt,flags:f,cost,a,spl:st.spl+sp,extra});
  }
  states=[...next.values()].sort((a,b)=>lex(a.cost,b.cost)).slice(0,6500);
  if(!states.length)return null;
 }
 let best=null;
 for(const st of states){
  const c=st.cnt,f=st.flags;
  if(c[1]!==4||c[2]<5||c[3]<5||c[4]<5||c[5]!==exact17||c[6]!==exact17||c[7]!==4||f.some(x=>!x))continue;
  if(!best||lex(st.cost,best.cost)<0)best=st;
 }
 return best;
}
function applySolution(w,d,sol,ctx){
 for(const [n,s] of Object.entries(sol.a))w.schedule[n][d]=s;
 for(const n of Object.keys(sol.a)){
  const ex=sol.extra[n]||0;if(ex)ctx.priorOT[n]=(ctx.priorOT[n]||0)+ex;
  if(isSplit(sol.a[n])){ctx.priorSplit[n]=(ctx.priorSplit[n]||0)+1;ctx.totalSplit++}
 }
}
function zeroSplitWeek(w){
 const ctx={allowSplit:false,normal:true,respShortage:false,priorOT:{},priorSplit:{},totalSplit:0};
 for(let d=0;d<6;d++){
  const active=ALL.filter(n=>works(w.schedule[n]?.[d])),fixed={};
  const sol=solveDay(w,d,active,fixed,ctx);if(!sol)throw new Error(`${C.dateLabel(w.dates[d])}: non riesco a creare la settimana normale senza spezzati.`);
  applySolution(w,d,sol,ctx);
 }
 w.smartV123=true;w.smartMode='normale-0-spezzati';return w;
}
function repairSunday(w,acc,abs){
 const d=6,date=w.dates[d],groups=[RESP,CASH,FLOOR];
 for(const n of ALL){
  const v=wantedOn(n,date,acc,abs);
  if(v&&absentValue(v))w.schedule[n][d]=String(v).toUpperCase();
  else if(v&&!absentValue(v))w.schedule[n][d]=v;
 }
 for(const g of groups){
  const req=g===FLOOR?2:1;
  let cur=g.filter(n=>works(w.schedule[n]?.[d])&&!absentValue(wantedOn(n,date,acc,abs)));
  if(cur.length>req){const rem=cur.filter(n=>!wantedOn(n,date,acc,abs));while(cur.length>req&&rem.length){const n=rem.shift();w.schedule[n][d]='RIPOSO';cur=cur.filter(x=>x!==n)}}
  if(cur.length<req){
   const cand=g.filter(n=>!cur.includes(n)&&!absentValue(wantedOn(n,date,acc,abs))).sort((a,b)=>C.weekHours(w,a)-C.weekHours(w,b));
   while(cur.length<req&&cand.length){const n=cand.shift();w.schedule[n][d]='08:00-13:00';cur.push(n)}
  }
 }
 w.schedule.Marco[d]='RIPOSO';
}
function smartWeek(w,acc,abs){
 const constraints=weekConstraints(w,acc,abs),absPeople=[...new Set(constraints.filter(x=>absentValue(x.wanted)).map(x=>x.employee))];
 if(!constraints.length)return zeroSplitWeek(w);
 const original=clone(w.schedule),sun=sundayWorkers(w),two=absPeople.length>=2;
 const ctx={allowSplit:true,normal:false,respShortage:absPeople.some(n=>RESP.includes(n)),priorOT:{},priorSplit:{},totalSplit:0};
 for(let d=0;d<6;d++){
  const date=w.dates[d],fixed={},active=[];
  for(const n of ALL){
   const want=wantedOn(n,date,acc,abs);
   if(want&&absentValue(want)){w.schedule[n][d]=String(want).toUpperCase();continue}
   if(want&&!absentValue(want))fixed[n]=want;
   let should=works(original[n]?.[d])||!!fixed[n];
   if(two&&n!=='Marco'&&!absPeople.includes(n)&&!sun.has(n))should=true;
   if(should)active.push(n);else w.schedule[n][d]=original[n]?.[d]||'RIPOSO';
  }
  let sol=solveDay({...w,schedule:original},d,active,fixed,ctx);
  if(!sol&&!two){
   const resters=ALL.filter(n=>n!=='Marco'&&!active.includes(n)&&!absentValue(wantedOn(n,date,acc,abs)));
   const preferred=[...resters.filter(n=>CASH.includes(n)||FLOOR.includes(n)),...resters.filter(n=>RESP.includes(n))];
   for(const n of preferred){
    const trial=[...active,n];sol=solveDay({...w,schedule:original},d,trial,fixed,ctx);
    if(sol){active.push(n);break}
   }
  }
  if(!sol)throw new Error(`${C.dateLabel(date)}: non trovo una combinazione valida con le assenze/richieste inserite.`);
  applySolution(w,d,sol,ctx);
 }
 repairSunday(w,acc,abs);
 w.smartV123=true;w.smartMode=two?'assenze-2+':'assenze-1';w.constraintsRespShortage=ctx.respShortage;
 w.v123Overtime=Object.fromEntries(ALL.map(n=>[n,Math.max(0,C.weekHours(w,n)-(C.TARGET[n]||0))]));
 w.v123Splits=Object.fromEntries(ALL.map(n=>[n,(w.schedule[n]||[]).filter(isSplit).length]));
 return w;
}
function baseGenerate(start){
 const oldAbs=localStorage.getItem(ABS_KEY),oldReq=localStorage.getItem(REQ_KEY);
 try{saveRaw(ABS_KEY,[]);saveRaw(REQ_KEY,[]);return PREV.generate(start)}
 finally{
  if(oldAbs===null)localStorage.removeItem(ABS_KEY);else localStorage.setItem(ABS_KEY,oldAbs);
  if(oldReq===null)localStorage.removeItem(REQ_KEY);else localStorage.setItem(REQ_KEY,oldReq);
 }
}
function generate(start){
 const data=baseGenerate(start),acc=accepted(),abs=absences();
 data.weeks.forEach(w=>smartWeek(w,acc,abs));
 data.generator='v123-smart';data.constraints={acceptedRequests:acc,absences:abs};return data;
}
function add(out,type,wi,date,employee,message){out.push({type,weekIndex:wi,date,employee,message})}
function validateSmartWeek(w,wi){
 const out=[];
 for(let d=0;d<7;d++){
  const date=w.dates[d],sun=C.isSunday(date);
  if(sun){
   const rr=RESP.filter(n=>works(w.schedule[n]?.[d])),cc=CASH.filter(n=>works(w.schedule[n]?.[d])),ff=FLOOR.filter(n=>works(w.schedule[n]?.[d]));
   if(rr.length!==1)add(out,'domenica',wi,date,null,`${C.dateLabel(date)}: deve lavorare 1 Responsabile`);
   if(cc.length!==1)add(out,'domenica',wi,date,null,`${C.dateLabel(date)}: deve lavorare 1 Cassa`);
   if(ff.length!==2)add(out,'domenica',wi,date,null,`${C.dateLabel(date)}: devono lavorare 2 Sala`);
   continue;
  }
  const count=t=>ALL.reduce((z,n)=>z+(at(w.schedule[n]?.[d],t)?1:0),0),marco=works(w.schedule.Marco?.[d]),need=marco?5:4;
  if(count('07:00')!==4)add(out,'copertura',wi,date,null,`${C.dateLabel(date)}: alle 07:00 devono esserci esattamente 4 persone`);
  if(!RESP.some(n=>at(w.schedule[n]?.[d],'06:45'))||!FLOOR.some(n=>at(w.schedule[n]?.[d],'06:45')))add(out,'apertura',wi,date,null,`${C.dateLabel(date)}: prima delle 07:00 servono Responsabile + Sala`);
  for(const t of ['10:00','13:30','16:30'])if(count(t)<5)add(out,'copertura',wi,date,null,`${C.dateLabel(date)}: alle ${t} servono almeno 5 persone`);
  if(count('17:00')!==need||count('19:59')!==need)add(out,'copertura',wi,date,null,`${C.dateLabel(date)}: fascia serale non valida`);
  if(count('20:29')!==4)add(out,'chiusura',wi,date,null,`${C.dateLabel(date)}: chiusura deve avere 4 persone`);
  if(!CASH.some(n=>at(w.schedule[n]?.[d],'07:00'))||!CASH.some(n=>at(w.schedule[n]?.[d],'13:30'))||!CASH.some(n=>at(w.schedule[n]?.[d],'20:29')))add(out,'cassa',wi,date,null,`${C.dateLabel(date)}: copertura Cassa incompleta`);
 }
 const splits=ALL.reduce((z,n)=>z+(w.schedule[n]||[]).filter(isSplit).length,0);
 if(w.smartMode==='normale-0-spezzati'&&splits!==0)add(out,'spezzati',wi,null,null,`Settimana normale: devono esserci 0 spezzati`);
 if(w.smartMode!=='normale-0-spezzati'&&splits>5)add(out,'spezzati',wi,null,null,`Settimana con assenze: ${splits} spezzati, massimo 5`);
 for(const n of ALL){
  const sp=(w.schedule[n]||[]).filter(isSplit).length;if(w.smartMode!=='normale-0-spezzati'&&sp>1)add(out,'spezzati',wi,null,n,`${n}: massimo 1 spezzato nella settimana`);
  if(n==='Marco'&&Math.abs(C.weekHours(w,n)-16)>.001)add(out,'marco',wi,null,n,`Marco: ${C.weekHours(w,n)}h invece di 16h`);
  if(w.smartMode==='normale-0-spezzati'&&Math.abs(C.weekHours(w,n)-C.TARGET[n])>.001)add(out,'ore',wi,null,n,`${n}: ${C.weekHours(w,n)}h invece di ${C.TARGET[n]}h`);
  if(RESP.includes(n)&&w.smartMode!=='normale-0-spezzati'&&!w.constraintsRespShortage&&C.weekHours(w,n)>40.001)add(out,'ore',wi,null,n,`${n}: straordinario Responsabile non necessario`);
 }
 return out;
}
function validateSchedule(data){
 const out=[];(data?.weeks||[]).forEach((w,wi)=>out.push(...(w.smartV123?validateSmartWeek(w,wi):PREV.validateSchedule({weeks:[w]}))));
 return out;
}
window.TM112={generate,validateSchedule};
window.TM123={generate,validateSchedule};
document.documentElement.dataset.turniGenerator='v123';
})();