(()=>{
'use strict';
const C=window.TM91,LEGACY=window.TM112,BASE=window.TM_TEMPLATE_BASE_V139,BAL=window.TM_BALANCE_V139;
if(!C||!LEGACY||!BASE)return;
const ABS='tm_v125_absences',REQ='tm_v125_requests';
const RESP=[...C.RESPONSABILI],CASH=[...C.CASSA],FLOOR=['Giuliano','Manuel','Daniele','Paolo'],PEOPLE=[...RESP,...CASH,...C.SALA];
const OFF=new Set(['RIPOSO','FERIE','PERMESSO','MALATTIA','MATERNITÀ','—']);
const works=s=>C.works(s), at=(s,t)=>C.at(s,t), hours=s=>C.hours(s);
function load(k,d=[]){try{return JSON.parse(localStorage.getItem(k)||JSON.stringify(d))??d}catch{return d}}
function role(n){return RESP.includes(n)?'resp':CASH.includes(n)?'cash':FLOOR.includes(n)?'floor':n==='Marco'?'marco':''}
function absentOn(abs,n,date){return abs.find(x=>x.employee===n&&x.from&&x.to&&date>=x.from&&date<=x.to)||null}
function dayValid(w,d){const date=w.dates[d];if(C.isSunday(date))return RESP.filter(n=>works(w.schedule[n]?.[d])).length===1&&CASH.filter(n=>works(w.schedule[n]?.[d])).length===1&&FLOOR.filter(n=>works(w.schedule[n]?.[d])).length===2&&!works(w.schedule.Marco?.[d]);const count=t=>PEOPLE.reduce((z,n)=>z+(at(w.schedule[n]?.[d],t)?1:0),0),m=works(w.schedule.Marco?.[d]),need=m?5:4;return count('07:00')===4&&RESP.some(n=>at(w.schedule[n]?.[d],'06:45'))&&FLOOR.some(n=>at(w.schedule[n]?.[d],'06:45'))&&count('10:00')>=5&&count('13:30')>=5&&count('16:30')>=5&&count('17:00')===need&&count('19:59')===need&&count('20:29')===4&&CASH.some(n=>at(w.schedule[n]?.[d],'07:00'))&&CASH.some(n=>at(w.schedule[n]?.[d],'13:30'))&&CASH.some(n=>at(w.schedule[n]?.[d],'20:29'))}
function sameSundayRole(a,b){return role(a)===role(b)&&role(a)!=='marco'}
function sortCandidates(list,missingRole,extra){return list.sort((a,b)=>{const pa=role(a)===missingRole?0:(role(a)==='resp'?3:1),pb=role(b)===missingRole?0:(role(b)==='resp'?3:1);return pa-pb+(extra[a]||0)-(extra[b]||0)})}
function repairDay(w,d,abs,extra){const date=w.dates[d],original={};PEOPLE.forEach(n=>original[n]=w.schedule[n]?.[d]||'RIPOSO');const missing=[];for(const n of PEOPLE){const a=absentOn(abs,n,date);if(!a)continue;const old=original[n];w.schedule[n][d]=String(a.type||'FERIE').toUpperCase();if(works(old))missing.push({employee:n,shift:old,role:role(n)})}
if(!missing.length||dayValid(w,d))return true;
const snapshot=()=>Object.fromEntries(PEOPLE.map(n=>[n,w.schedule[n][d]])),restore=s=>PEOPLE.forEach(n=>w.schedule[n][d]=s[n]);
function recurse(i){if(i>=missing.length)return dayValid(w,d);const m=missing[i];
 let resters=PEOPLE.filter(n=>n!=='Marco'&&!absentOn(abs,n,date)&&!works(w.schedule[n][d]));
 if(C.isSunday(date))resters=resters.filter(n=>sameSundayRole(n,m.employee));
 sortCandidates(resters,m.role,extra);
 for(const r of resters){const s=snapshot();w.schedule[r][d]=m.shift;if(recurse(i+1)){extra[r]=(extra[r]||0)+hours(m.shift);return true}restore(s)}
 if(C.isSunday(date))return false;
 const active=PEOPLE.filter(n=>n!==m.employee&&n!=='Marco'&&!absentOn(abs,n,date)&&works(w.schedule[n][d]));
 sortCandidates(active,m.role,extra);
 for(const a of active){const old=w.schedule[a][d];const afterRest=PEOPLE.filter(n=>n!=='Marco'&&n!==a&&!absentOn(abs,n,date)&&!works(w.schedule[n][d]));sortCandidates(afterRest,role(a),extra);
  for(const r of afterRest){const s=snapshot();w.schedule[a][d]=m.shift;w.schedule[r][d]=old;if(recurse(i+1)){extra[r]=(extra[r]||0)+hours(old);extra[a]=(extra[a]||0)+Math.max(0,hours(m.shift)-hours(old));return true}restore(s)}
 }
 return false}
const before=snapshot();if(recurse(0))return true;restore(before);return false}
function relevantAbs(start,abs){const a=new Date(start+'T12:00:00');a.setDate(a.getDate()-((a.getDay()+6)%7));const b=new Date(a);b.setDate(b.getDate()+20);const lo=a.toISOString().slice(0,10),hi=b.toISOString().slice(0,10);return abs.filter(x=>x.from&&x.to&&x.to>=lo&&x.from<=hi)}
function relevantReq(){return load(REQ,[]).some(x=>x?.status==='ACCETTATA')}
function generate(start){const abs=relevantAbs(start,load(ABS,[]));if(!abs.length||relevantReq())return LEGACY.generate(start);const data=BASE.generate(start),extra={};for(const w of data.weeks){for(let d=0;d<7;d++){if(!w.dates[d])continue;const any=abs.some(x=>x.from<=w.dates[d]&&x.to>=w.dates[d]);if(!any)continue;if(!repairDay(w,d,abs,extra))return LEGACY.generate(start)}}data.constraints={acceptedRequests:[],absences:abs};data.generator='v201-fast-absence';if(BAL)BAL.apply(data);return data}
function validateSchedule(data){return LEGACY.validateSchedule?.(data)||[]}
window.TM112={generate,validateSchedule};window.TM_FAST_V201={generate,validateSchedule};
})();