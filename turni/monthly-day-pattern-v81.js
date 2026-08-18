(()=>{
'use strict';
const PEOPLE=['Umberto','Fabio','Emanuele','Stefania B','Giada','Giuliano','Daniele','Manuel','Romina','Stefania F','Paolo','Marco'];
const RESP=new Set(['Umberto','Fabio','Emanuele']);
const CASH=new Set(['Stefania B','Giada','Romina','Stefania F']);
const BACKUP=new Set(['Giuliano','Daniele','Manuel']);
const SALA=new Set(['Giuliano','Daniele','Manuel','Paolo','Marco']);
const OFF=new Set(['RIPOSO','FERIE','MALATTIA','MATERNITÀ','PERMESSO','—']);
const MANUAL='tm_monthly_manual_overrides_v1';
let running=false,lastApplied='';
const hm=t=>{const [h,m]=String(t).split(':').map(Number);return h*60+m};
function spans(s){if(!s||OFF.has(s))return[];return String(s).split('/').map(x=>x.trim()).map(x=>{const [a,b]=x.split('-').map(v=>hm(v.trim()));return Number.isFinite(a)&&Number.isFinite(b)&&b>a?[a,b]:null}).filter(Boolean)}
const works=s=>spans(s).length>0;
const at=(s,t)=>{const x=hm(t);return spans(s).some(([a,b])=>a<=x&&x<b)};
const starts=(s,t)=>{const x=hm(t);return spans(s).some(([a])=>a===x)};
const hours=s=>spans(s).reduce((z,[a,b])=>z+(b-a)/60,0);
const draft=()=>{try{return JSON.parse(localStorage.getItem('tm_planner_draft')||'null')}catch{return null}};
const manuals=()=>{try{const a=JSON.parse(localStorage.getItem(MANUAL)||'[]');return new Set((Array.isArray(a)?a:[]).map(x=>`${x.employee}|${x.date}`))}catch{return new Set()}};
function minuteString(t){return String(Math.floor(t/60)).padStart(2,'0')+':'+String(t%60).padStart(2,'0')}
function active(w,i,t,pred=()=>true){return PEOPLE.filter(n=>pred(n)&&at(w.schedule?.[n]?.[i],t))}
function cashWorkers(w,i,t){return active(w,i,t,n=>CASH.has(n)||BACKUP.has(n))}
function effectiveSala(w,i,t){const dedicated=active(w,i,t,n=>CASH.has(n));const backups=active(w,i,t,n=>BACKUP.has(n));const usedAsCash=dedicated.length?null:(backups[0]||null);return active(w,i,t,n=>SALA.has(n)&&n!==usedAsCash)}
function continuous(a,b,fn){for(let t=hm(a);t<hm(b);t+=15)if(!fn(minuteString(t)))return false;return true}
function validMorning(w,i){return continuous('07:00','13:30',t=>active(w,i,t).length>=4&&active(w,i,t,n=>RESP.has(n)).length>=1&&cashWorkers(w,i,t).length>=1&&effectiveSala(w,i,t).length>=2)&&PEOPLE.some(n=>SALA.has(n)&&starts(w.schedule[n][i],'06:30'))}
function validEvening(w,i){return continuous('17:00','20:30',t=>active(w,i,t).length>=4&&active(w,i,t,n=>RESP.has(n)).length>=1&&cashWorkers(w,i,t).length>=2&&effectiveSala(w,i,t).length>=1)}
function minCount(w,i,a,b){let z=99;for(let t=hm(a);t<hm(b);t+=15)z=Math.min(z,active(w,i,minuteString(t)).length);return z===99?0:z}
function monthHours(w,n){return (w.schedule?.[n]||[]).reduce((z,s)=>z+hours(s),0)}
function weekHours(w,n,i){const d=new Date(w.dates[i]+'T12:00:00'),dow=(d.getDay()+6)%7,start=i-dow;let z=0;for(let k=Math.max(0,start);k<Math.min(w.dates.length,start+7);k++)z+=hours(w.schedule[n][k]);return z}
function capOk(w,n,i,shift){const gain=hours(shift)-hours(w.schedule[n][i]);if(gain<=0)return true;if(n==='Marco')return weekHours(w,n,i)+gain<=17.5;if(n==='Giada')return weekHours(w,n,i)+gain<=34;return monthHours(w,n)+gain<=183}
function canChange(w,n,i,locks){const s=w.schedule?.[n]?.[i];return !RESP.has(n)&&!locks.has(`${n}|${w.dates[i]}`)&&works(s)&&!OFF.has(s)}
function score(w,n,i,shift){const gain=hours(shift)-hours(w.schedule[n][i]);let target=n==='Giada'?30:n==='Marco'?16:172.5,after=n==='Giada'||n==='Marco'?weekHours(w,n,i)+gain:monthHours(w,n)+gain;return Math.abs(target-after)+Math.max(0,gain)*.15}
function tryShift(w,n,i,shift,locks,checkMorning=true){if(!canChange(w,n,i,locks)||!capOk(w,n,i,shift))return false;const old=w.schedule[n][i];w.schedule[n][i]=shift;if(checkMorning&&!validMorning(w,i)){w.schedule[n][i]=old;return false}return true}
function best(w,i,list,shift,locks,filter=()=>true){return list.filter(n=>canChange(w,n,i,locks)&&filter(n)&&capOk(w,n,i,shift)).sort((a,b)=>score(w,a,i,shift)-score(w,b,i,shift))[0]||null}
function bridgeDay(w,i,locks){const dow=new Date(w.dates[i]+'T12:00:00').getDay();if(![1,3,4].includes(dow))return;let guard=0;while(minCount(w,i,'11:00','17:00')<5&&guard++<5){const candidates=PEOPLE.filter(n=>!RESP.has(n)&&n!=='Marco');const n=best(w,i,candidates,'11:00-20:00',locks,x=>!at(w.schedule[x][i],'11:00')||!at(w.schedule[x][i],'16:45'));if(!n)break;const old=w.schedule[n][i];if(!tryShift(w,n,i,'11:00-20:00',locks,true)){break}if(minCount(w,i,'11:00','17:00')<=minCount({...w,schedule:{...w.schedule,[n]:w.schedule[n].map((s,k)=>k===i?old:s)}},i,'11:00','17:00')){w.schedule[n][i]=old;break}}
}
function eveningDay(w,i,locks){
 if(validEvening(w,i))return;
 if(canChange(w,'Marco',i,locks)&&works(w.schedule.Marco[i])&&!at(w.schedule.Marco[i],'20:29')&&capOk(w,'Marco',i,'16:00-20:30'))tryShift(w,'Marco',i,'16:00-20:30',locks,true);
 let guard=0;
 while(!continuous('17:00','20:30',t=>cashWorkers(w,i,t).length>=2)&&guard++<5){const list=[...CASH,...BACKUP];const n=best(w,i,list,'13:30-20:30',locks,x=>!at(w.schedule[x][i],'20:29'));if(!n||!tryShift(w,n,i,'13:30-20:30',locks,true))break}
 guard=0;
 while(!validEvening(w,i)&&guard++<5){const n=best(w,i,[...SALA].filter(x=>x!=='Marco'),'13:30-20:30',locks,x=>!at(w.schedule[x][i],'20:29'));if(n&&tryShift(w,n,i,'13:30-20:30',locks,true))continue;
  const split=best(w,i,PEOPLE.filter(x=>!RESP.has(x)&&x!=='Marco'),'07:00-10:00 / 17:00-20:30',locks,x=>starts(w.schedule[x][i],'07:00')||starts(w.schedule[x][i],'06:30'));
  if(split&&tryShift(w,split,i,'07:00-10:00 / 17:00-20:30',locks,true))continue;break}
}
function preferBridgeWhenSafe(w,i,locks){const dow=new Date(w.dates[i]+'T12:00:00').getDay();if(![1,3,4].includes(dow)||!validEvening(w,i)||minCount(w,i,'11:00','17:00')<5)return;const hasBridge=PEOPLE.some(n=>w.schedule[n][i]==='11:00-20:00');if(hasBridge)return;const list=PEOPLE.filter(n=>!RESP.has(n)&&n!=='Marco'&&canChange(w,n,i,locks));for(const n of list.sort((a,b)=>score(w,a,i,'11:00-20:00')-score(w,b,i,'11:00-20:00'))){const old=w.schedule[n][i];if(hours(old)>=8||!capOk(w,n,i,'11:00-20:00'))continue;w.schedule[n][i]='11:00-20:00';if(validMorning(w,i)&&minCount(w,i,'11:00','17:00')>=5&&validEvening(w,i))return;w.schedule[n][i]=old}}
function apply(){if(running)return;const d=draft(),w=d?.week;if(!w?.dates?.length||!w.schedule)return;const signature=JSON.stringify(w.schedule);if(signature===lastApplied)return;running=true;try{const locks=manuals();let changed=false;const before=JSON.stringify(w.schedule);for(let i=0;i<w.dates.length;i++){const dow=new Date(w.dates[i]+'T12:00:00').getDay();if(dow===0)continue;bridgeDay(w,i,locks);eveningDay(w,i,locks);preferBridgeWhenSafe(w,i,locks)}changed=before!==JSON.stringify(w.schedule);lastApplied=JSON.stringify(w.schedule);if(changed){d.week=w;localStorage.setItem('tm_planner_draft',JSON.stringify(d));window.dispatchEvent(new CustomEvent('tm:draft-changed',{detail:{source:'schema-giornata-v81'}}))}}finally{running=false}}
let timer=null;new MutationObserver(()=>{clearTimeout(timer);timer=setTimeout(apply,220)}).observe(document.getElementById('app'),{childList:true,subtree:true});window.addEventListener('load',()=>setTimeout(apply,700));window.addEventListener('tm:draft-changed',()=>setTimeout(apply,120));
})();