(()=>{
'use strict';
const KEY='tm_monthly_coverage_optimizer_v76';
const PEOPLE=['Umberto','Fabio','Emanuele','Stefania B','Giada','Giuliano','Daniele','Manuel','Romina','Stefania F','Paolo','Marco'];
const RESP=new Set(['Umberto','Fabio','Emanuele']);
const OFF=new Set(['RIPOSO','FERIE','MALATTIA','MATERNITÀ','PERMESSO','—']);
const prevApi=api;
const load=()=>{try{const x=JSON.parse(localStorage.getItem(KEY)||'[]');return Array.isArray(x)?x:[]}catch{return[]}};
const save=x=>localStorage.setItem(KEY,JSON.stringify(x));
const draft=()=>{try{return JSON.parse(localStorage.getItem('tm_planner_draft')||'null')?.week||null}catch{return null}};
const fmt=d=>new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(d+'T12:00:00'));
function parts(s){if(!s||OFF.has(s))return[];return String(s).split('/').map(x=>x.trim()).map(x=>{const p=x.split('-').map(v=>hm(v.trim()));return p.length===2&&Number.isFinite(p[0])&&Number.isFinite(p[1])&&p[1]>p[0]?p:null}).filter(Boolean)}
const works=s=>parts(s).length>0;
const hours=s=>parts(s).reduce((z,[a,b])=>z+(b-a)/60,0);
const at=(s,t)=>{const x=hm(t);return parts(s).some(([a,b])=>a<=x&&x<b)};
function acceptedCell(x){if(x.status!=='ACCETTATA')return null;const g=String(x.message||'').match(/Giorno:\s*([^\n]+).*?Turno richiesto:\s*([^\n]+)/s);if(!g)return null;return x.employee+'|'+g[1].trim()}
function isSoftAuto(x){const id=String(x.id||''),m=String(x.message||'');return /^(optimizer-|balance-|streak-)/.test(id)||/Origine:\s*(riparazione automatica|bilanciamento automatico|correzione automatica)/i.test(m)}
function optimizerRequests(base){const occupied=new Set((base||[]).filter(x=>!isSoftAuto(x)).map(acceptedCell).filter(Boolean));return load().filter(x=>!occupied.has(x.employee+'|'+fmt(x.date))).map(x=>({id:'optimizer-v76-'+x.employee+'-'+x.date,employee:x.employee,status:'ACCETTATA',replied_at:new Date().toISOString(),message:`Giorno: ${fmt(x.date)}\nTurno richiesto: ${x.shift}\nOrigine: riparazione automatica coperture`}))}
api=async function(action,opts={}){const r=await prevApi(action,opts);if(action==='list_requests'){const base=Array.isArray(r.requests)?r.requests:[];return{...r,requests:[...base,...optimizerRequests(base)]}}return r};
function monthHours(w,n){return(w.schedule[n]||[]).reduce((z,s)=>z+hours(s),0)}
function cap(n){if(RESP.has(n))return Infinity;if(n==='Marco')return 80;if(n==='Giada')return 145;return 182.9}
function scoreCandidate(w,n,i,newShift,reason){const old=w.schedule[n][i],gain=hours(newShift)-hours(old),after=monthHours(w,n)+gain;if(gain<0||after>cap(n))return Infinity;let score=Math.abs((n==='Giada'?130:172.5)-after);if(RESP.has(n))score+=1000;if((reason==='band'||reason==='eleven')&&gain<=2)score-=5;return score}
function setPlan(plan,w,n,i,shift){if(!n||!shift||w.schedule[n][i]===shift)return false;plan.set(n+'|'+w.dates[i],{employee:n,date:w.dates[i],shift});w.schedule[n][i]=shift;return true}
function extendOptions(s,reason){const m={'06:30-13:30':['06:30-15:30','06:30-14:30'],'07:00-14:00':['07:00-16:00','07:00-15:00'],'07:00-13:00':['07:00-16:00','07:00-13:00 / 17:00-20:00'],'09:00-14:00':['09:00-18:00','09:00-17:00'],'10:00-17:00':['10:00-19:00','10:00-18:00'],'11:00-18:00':['11:00-20:00','11:00-19:00'],'13:30-20:30':['11:30-20:30','12:00-20:30','11:00-14:00 / 17:00-20:30'],'14:00-20:30':['11:30-20:30','12:00-20:30','11:00-14:00 / 17:00-20:30'],'16:00-20:00':['11:00-14:00 / 17:00-20:00'],'16:30-20:30':['11:00-14:00 / 17:00-20:30']};let a=m[s]||[];if(reason==='eleven')a=a.filter(x=>at(x,'11:00'));if(reason==='band')a=a.filter(x=>at(x,'13:30')&&at(x,'16:15'));return a}
function bestExtension(w,i,reason,blocked){let best=null,bestScore=Infinity;for(const n of PEOPLE){if(n==='Marco'||blocked.has(n+'|'+fmt(w.dates[i]))||!works(w.schedule[n][i]))continue;for(const sh of extendOptions(w.schedule[n][i],reason)){const sc=scoreCandidate(w,n,i,sh,reason);if(sc<bestScore){bestScore=sc;best={n,sh}}}}return best}
function countAt(w,i,t){return PEOPLE.filter(n=>at(w.schedule[n][i],t)).length}
function intervalMin(w,i,a,b){let min=99;for(let t=hm(a);t<hm(b);t+=15){const h=String(Math.floor(t/60)).padStart(2,'0')+':'+String(t%60).padStart(2,'0');min=Math.min(min,countAt(w,i,h))}return min===99?0:min}
async function optimize(){if(window.__tmFatal)return;const w=draft();if(!w?.dates?.length)return;let base=[];try{base=(await prevApi('list_requests')).requests||[]}catch{}const blocked=new Set(base.filter(x=>!isSoftAuto(x)).map(acceptedCell).filter(Boolean));const clone={...w,schedule:Object.fromEntries(PEOPLE.map(n=>[n,[...(w.schedule[n]||[])]]))};const plan=new Map();for(let i=0;i<clone.dates.length;i++){const d=new Date(clone.dates[i]+'T12:00:00');if(d.getDay()===0)continue;let guard=0;while(countAt(clone,i,'11:00')<5&&guard++<8){const b=bestExtension(clone,i,'eleven',blocked);if(!b||!setPlan(plan,clone,b.n,i,b.sh))break}const need=[1,3,4].includes(d.getDay())?5:4,end=[1,3,4].includes(d.getDay())?'16:30':'17:00';guard=0;while(intervalMin(clone,i,'13:30',end)<need&&guard++<8){const b=bestExtension(clone,i,'band',blocked);if(!b||!setPlan(plan,clone,b.n,i,b.sh))break}}const next=[...plan.values()].sort((a,b)=>(a.date+a.employee).localeCompare(b.date+b.employee));const old=load().sort((a,b)=>(a.date+a.employee).localeCompare(b.date+b.employee));if(JSON.stringify(old)!==JSON.stringify(next)){save(next);window.tmOptimizationChanged?.('coperture')}}
let timer=null;new MutationObserver(()=>{clearTimeout(timer);timer=setTimeout(optimize,350)}).observe(document.getElementById('app'),{childList:true,subtree:true});window.addEventListener('load',()=>setTimeout(optimize,600));
})();