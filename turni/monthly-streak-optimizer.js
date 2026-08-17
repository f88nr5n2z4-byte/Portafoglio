(()=>{
'use strict';
const KEY='tm_monthly_streak_optimizer_v76';
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
function acceptedCell(x){if(x.status!=='ACCETTATA')return null;const g=String(x.message||'').match(/Giorno:\s*([^\n]+).*?Turno richiesto:\s*([^\n]+)/s);if(!g)return null;return x.employee+'|'+g[1].trim()}
function isSoftAuto(x){const id=String(x.id||''),m=String(x.message||'');return /^(optimizer-|balance-|streak-)/.test(id)||/Origine:\s*(riparazione automatica|bilanciamento automatico|correzione automatica)/i.test(m)}
function requests(base){const occupied=new Set((base||[]).filter(x=>!isSoftAuto(x)).map(acceptedCell).filter(Boolean));return load().filter(x=>!occupied.has(x.employee+'|'+fmt(x.date))).map(x=>({id:'streak-v76-'+x.employee+'-'+x.date,employee:x.employee,status:'ACCETTATA',replied_at:new Date().toISOString(),message:`Giorno: ${fmt(x.date)}\nTurno richiesto: RIPOSO\nOrigine: correzione automatica massimo 6 giorni consecutivi`}))}
api=async function(action,opts={}){const r=await prevApi(action,opts);if(action==='list_requests'){const base=Array.isArray(r.requests)?r.requests:[];return{...r,requests:[...base,...requests(base)]}}return r};
function totalWorking(w,i){return PEOPLE.filter(n=>works(w.schedule?.[n]?.[i])).length}
function priorStreak(n,w,official){const first=w.dates[0],map=new Map();for(const pw of(official?.weeks||[]))for(let i=0;i<(pw.dates||[]).length;i++){const d=pw.dates[i];if(d<first)map.set(d,pw.schedule?.[n]?.[i])}let d=new Date(first+'T12:00:00'),streak=0;for(let k=1;k<=14;k++){const x=new Date(d);x.setDate(x.getDate()-k);const iso=x.toLocaleDateString('sv-SE');if(works(map.get(iso)))streak++;else break}return streak}
function candidateScore(w,n,i){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)return Infinity;let score=-totalWorking(w,i)*20+i*.05;if(d.getDay()===6)score+=4;if(RESP.has(n)){const others=[...RESP].filter(x=>x!==n&&works(w.schedule?.[x]?.[i])).length;if(others<2)return Infinity;score+=10}return score}
async function optimize(){if(window.__tmFatal)return;const w=draft();if(!w?.dates?.length||!w.schedule)return;let base=[],official={weeks:[]};try{const r=await prevApi('list_requests');base=r.requests||[]}catch{}try{const r=await prevApi('get_schedule');if(r.data?.weeks)official=r.data}catch{}
 const blocked=new Set(base.filter(x=>!isSoftAuto(x)).map(acceptedCell).filter(Boolean));const clone={...w,schedule:Object.fromEntries(PEOPLE.map(n=>[n,[...(w.schedule[n]||[])]]))};const plan=[];
 for(const n of PEOPLE){if(n==='Marco')continue;let guard=0;while(guard++<20){let streak=priorStreak(n,clone,official),vi=-1,runStart=0;for(let i=0;i<clone.dates.length;i++){if(works(clone.schedule[n][i])){if(streak===0)runStart=i;streak++;if(streak>6){vi=i;break}}else{streak=0;runStart=i+1}}if(vi<0)break;const from=Math.max(runStart,vi-5),cand=[];for(let i=from;i<=vi;i++){if(!works(clone.schedule[n][i]))continue;const lab=fmt(clone.dates[i]);if(blocked.has(n+'|'+lab))continue;const sc=candidateScore(clone,n,i);if(Number.isFinite(sc))cand.push({i,sc})}if(!cand.length)break;cand.sort((a,b)=>a.sc-b.sc||a.i-b.i);const i=cand[0].i;clone.schedule[n][i]='RIPOSO';plan.push({employee:n,date:clone.dates[i],shift:'RIPOSO'});blocked.add(n+'|'+fmt(clone.dates[i]))}}
 const next=[...new Map(plan.map(x=>[x.employee+'|'+x.date,x])).values()].sort((a,b)=>(a.date+a.employee).localeCompare(b.date+b.employee));const old=load().sort((a,b)=>(a.date+a.employee).localeCompare(b.date+b.employee));if(JSON.stringify(old)!==JSON.stringify(next)){save(next);window.tmOptimizationChanged?.('massimo 6 giorni')}}
let timer=null;new MutationObserver(()=>{clearTimeout(timer);timer=setTimeout(optimize,450)}).observe(document.getElementById('app'),{childList:true,subtree:true});window.addEventListener('load',()=>setTimeout(optimize,700));
})();