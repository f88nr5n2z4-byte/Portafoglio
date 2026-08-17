const u=requireUser(true),app=document.getElementById('app');
const NAMES=['Umberto','Fabio','Emanuele','Stefania B','Giada','Giuliano','Daniele','Manuel','Romina','Stefania F','Paolo','Marco'];
const RESPONSIBILI=['Umberto','Fabio','Emanuele'];
const OPERATIVI=['Stefania B','Giada','Giuliano','Daniele','Manuel','Romina','Stefania F','Paolo','Marco'];
const CASSA=['Stefania B','Giada','Romina','Stefania F'];
const SALA=['Giuliano','Daniele','Manuel','Paolo','Marco'];
const SALA_CASSA=['Giuliano','Daniele','Manuel'];
const FULLTIME=OPERATIVI.filter(n=>!['Giada','Marco'].includes(n));
const PROTECTED=new Set(['FERIE','MALATTIA','MATERNITÀ','PERMESSO']);
const OFF=new Set(['RIPOSO','FERIE','MALATTIA','MATERNITÀ','PERMESSO','—']);
const SUNDAY_CREWS=[['Stefania B','Giuliano','Paolo'],['Giada','Daniele','Romina'],['Stefania F','Manuel','Marco']];
const RESP_ANCHOR=new Date('2026-08-23T12:00:00');
const OPS_ANCHOR=new Date('2026-08-23T12:00:00');
let official={weeks:[]},requests=[],draft=null,locked=new Set();

const css=document.createElement('style');css.textContent=`.nt{max-width:1180px;margin:auto;padding:12px}.nt-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}.nt-head a{font-weight:900;color:#0067b1}.card{background:#fff;border:1px solid #dbe5ec;border-radius:18px;padding:14px;margin-bottom:11px}.card h2,.card h3{margin:0 0 8px;color:#003d7c}.statusok{background:#edf9f0;border:1px solid #a7d8b2;color:#17602a;border-radius:14px;padding:12px;font-weight:900}.statusbad{background:#fff0f0;border:1px solid #e8b0b0;color:#8a2020;border-radius:14px;padding:12px;font-weight:900}.statuswarn{background:#fff8d4;border:1px solid #e7d36a;color:#665300;border-radius:14px;padding:12px;font-weight:850;margin-top:8px}.month-grid{overflow:auto;border:1px solid #dce6ed;border-radius:15px}.month-table{display:grid;grid-template-columns:115px repeat(var(--days),84px);min-width:max-content}.cell{padding:7px;border-right:1px solid #e3e9ee;border-bottom:1px solid #e3e9ee;font-size:10px;background:#fff}.head{font-weight:950;background:#eef5fa;color:#003d7c;position:sticky;top:0;z-index:3}.name{font-weight:950;color:#003d7c;position:sticky;left:0;z-index:2;background:#fff}.sun{background:#fff8cf}.rest{background:#f0f3f5;color:#667}.actions{display:grid;gap:8px}.publish{border:0;border-radius:13px;padding:14px;background:#0067b1;color:#fff;font-weight:950}.legend{font-size:12px;color:#526b7d}.checks{display:grid;gap:6px;font-size:12px}.checks b{color:#003d7c}@media(max-width:700px){.nt{padding:8px}.month-table{grid-template-columns:92px repeat(var(--days),78px)}}`;document.head.appendChild(css);

function iso(d){return d.toLocaleDateString('sv-SE')}
function daysInMonth(y,m){return new Date(y,m+1,0).getDate()}
function monthDates(y,m){return Array.from({length:daysInMonth(y,m)},(_,i)=>iso(new Date(y,m,i+1,12)))}
function monthLabel(y,m){return new Intl.DateTimeFormat('it-IT',{month:'long',year:'numeric'}).format(new Date(y,m,1)).replace(/^./,c=>c.toUpperCase())}
function sundayIndex(date,anchor=RESP_ANCHOR){const ms=date-anchor;return Math.floor(ms/(7*86400000))}
function sundayForDate(d){const x=new Date(d);const delta=(7-x.getDay())%7;x.setDate(x.getDate()+delta);return x}
function respSunday(date){return RESPONSIBILI[((sundayIndex(date)%3)+3)%3]}
function opsSundayCrew(date){return SUNDAY_CREWS[((sundayIndex(date,OPS_ANCHOR)%3)+3)%3]}
function span(s){if(!s||OFF.has(s))return[];return String(s).split('/').map(p=>p.trim()).map(p=>{const[a,b]=p.split('-');return[hm(a.trim()),hm(b.trim())]}).filter(([a,b])=>Number.isFinite(a)&&Number.isFinite(b)&&b>a)}
function works(s){return span(s).length>0}
function at(s,t){const x=hm(t);return span(s).some(([a,b])=>a<=x&&x<b)}
function begins(s,t){const x=hm(t);return span(s).some(([a])=>a===x)}
function hrs(s){return span(s).reduce((z,[a,b])=>z+(b-a)/60,0)}
function totalHours(w,n){return(w.schedule[n]||[]).reduce((z,s)=>z+hrs(s),0)}
function blankMonth(y,m){const dates=monthDates(y,m),schedule={};for(const n of NAMES)schedule[n]=Array(dates.length).fill('—');return{label:monthLabel(y,m),dates,schedule,period:'month',year:y,month:m+1}}
function set(w,n,i,s){if(!locked.has(`${n}|${i}`))w.schedule[n][i]=s}
function nextTargetMonth(){const now=new Date();if(official.weeks?.length){const last=official.weeks.slice().sort((a,b)=>String(a.dates?.[0]).localeCompare(String(b.dates?.[0]))).at(-1);if(last?.dates?.length){const d=new Date(last.dates.at(-1)+'T12:00:00');return[d.getFullYear(),d.getMonth()+1]}}
 return now.getDate()<=7?[now.getFullYear(),now.getMonth()]:[now.getFullYear(),now.getMonth()+1]
}
function normalizeYM(y,m){while(m>11){m-=12;y++}while(m<0){m+=12;y--}return[y,m]}
function weekdayRestForSunday(sunday,person,crew){const idx=crew.indexOf(person);const offsets=[-5,-4,-3];const d=new Date(sunday);d.setDate(d.getDate()+offsets[idx]);return iso(d)}
function respRestForSunday(sunday){const d=new Date(sunday);d.setDate(d.getDate()-3);return iso(d)}
function shouldRest(w,n,i){const d=new Date(w.dates[i]+'T12:00:00'),sun=sundayForDate(d);const siso=iso(sun);if(RESPONSIBILI.includes(n)&&respSunday(sun)===n&&w.dates[i]===respRestForSunday(sun))return true;const crew=opsSundayCrew(sun);if(crew.includes(n)&&w.dates[i]===weekdayRestForSunday(sun,n,crew))return true;return false}
function sundayAssign(w,i){const d=new Date(w.dates[i]+'T12:00:00'),r=respSunday(d),crew=opsSundayCrew(d);for(const n of NAMES)set(w,n,i,'RIPOSO');set(w,r,i,'08:00-13:00');for(const n of crew)set(w,n,i,'08:00-13:00')}
function choose(list,used,score){return list.filter(n=>!used.has(n)).sort((a,b)=>score(a)-score(b))[0]||null}
function weekKey(isoDate){const d=new Date(isoDate+'T12:00:00'),day=(d.getDay()+6)%7;d.setDate(d.getDate()-day);return iso(d)}
function currentWeekHours(w,n,i){const key=weekKey(w.dates[i]);let z=0;for(let k=0;k<=i;k++)if(weekKey(w.dates[k])===key)z+=hrs(w.schedule[n][k]);return z}
function targetWeek(n){return n==='Giada'?30:n==='Marco'?16:40}
function assignResponsible(w,i){const date=w.dates[i],d=new Date(date+'T12:00:00');if(d.getDay()===0)return;const resting=RESPONSIBILI.find(n=>shouldRest(w,n,i));const avail=RESPONSIBILI.filter(n=>n!==resting&&!PROTECTED.has(w.schedule[n][i]));const rot=i%3;
 if(avail.length===3){set(w,avail[rot%3],i,'06:30-13:30');set(w,avail[(rot+1)%3],i,'10:00-17:00');set(w,avail[(rot+2)%3],i,'13:30-20:30')}
 else if(avail.length===2){set(w,avail[0],i,'06:30-13:30');set(w,avail[1],i,'13:30-20:30')}
 if(resting)set(w,resting,i,'RIPOSO')
}
function assignMarco(w,i){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)return;if(shouldRest(w,'Marco',i)){set(w,'Marco',i,'RIPOSO');return}const sun=sundayForDate(d),worksSun=opsSundayCrew(sun).includes('Marco');const dow=d.getDay();let active=false;if(worksSun)active=[1,3,5].includes(dow);else active=[1,3,4,6].includes(dow);if(!active){set(w,'Marco',i,'—');return}const wh=currentWeekHours(w,'Marco',i);const remain=Math.max(0,16-wh);const len=Math.min(4,remain||4);if(len>=4)set(w,'Marco',i,'16:30-20:30');else if(len===3)set(w,'Marco',i,'17:30-20:30');else set(w,'Marco',i,'—')}
function assignOperationalDay(w,i){const date=w.dates[i],d=new Date(date+'T12:00:00');if(d.getDay()===0)return;for(const n of OPERATIVI){if(shouldRest(w,n,i))set(w,n,i,'RIPOSO')}
 assignMarco(w,i);
 const available=OPERATIVI.filter(n=>!OFF.has(w.schedule[n][i]));
 const used=new Set();
 const score=n=>currentWeekHours(w,n,i)/targetWeek(n);
 const cashAvail=CASSA.filter(n=>available.includes(n));
 let morningCash=choose(cashAvail,used,score);if(!morningCash)morningCash=choose(SALA_CASSA.filter(n=>available.includes(n)),used,score);if(morningCash){used.add(morningCash);set(w,morningCash,i,morningCash==='Giada'?'07:00-12:00':'07:00-14:00')}
 let sala630=choose(SALA.filter(n=>available.includes(n)&&n!=='Marco'),used,score);if(sala630){used.add(sala630);set(w,sala630,i,'06:30-13:30')}
 let sala2=choose(SALA.filter(n=>available.includes(n)&&n!=='Marco'),used,score);if(sala2){used.add(sala2);set(w,sala2,i,'07:00-14:00')}
 let aftCash=choose(cashAvail,used,score);if(!aftCash)aftCash=choose(SALA_CASSA.filter(n=>available.includes(n)),used,score);if(aftCash){used.add(aftCash);set(w,aftCash,i,aftCash==='Giada'?'13:30-18:30':'13:30-20:30')}
 const needClosers=3-(aftCash&&at(w.schedule[aftCash][i],'20:29')?1:0);for(let k=0;k<needClosers;k++){const n=choose(available.filter(x=>x!=='Marco'||works(w.schedule[x][i])),used,score);if(!n)break;used.add(n);set(w,n,i,'13:30-20:30')}
 // Le persone ancora disponibili vengono usate come centrali o turni semplici, privilegiando chi ha meno ore.
 for(const n of available.filter(x=>!used.has(x))){if(n==='Marco')continue;const wh=currentWeekHours(w,n,i),t=targetWeek(n);if(wh>=t){set(w,n,i,'—');continue}if(n==='Giada')set(w,n,i,'10:00-15:00');else set(w,n,i,'10:00-17:00');used.add(n)}
}
function buildMonth(y,m){const w=blankMonth(y,m);for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)sundayAssign(w,i);else{assignResponsible(w,i);assignOperationalDay(w,i)}}return w}
function parseAccepted(x){if(x.status!=='ACCETTATA'||!x.replied_at)return null;const g=String(x.message||'').match(/Giorno:\s*([^\n]+).*?Turno richiesto:\s*([^\n]+)/s);if(!g)return null;return{employee:x.employee,dateLabel:g[1].trim(),wanted:g[2].trim()}}
function applyAccepted(w){const used=[];for(const x of requests){const p=parseAccepted(x);if(!p||!w.schedule[p.employee])continue;const di=w.dates.findIndex(d=>fmtDate(d)===p.dateLabel);if(di<0)continue;w.schedule[p.employee][di]=p.wanted;locked.add(`${p.employee}|${di}`);used.push(p)}return used}
function dayStats(w,i){const active=NAMES.filter(n=>works(w.schedule[n][i]));const at11=active.filter(n=>at(w.schedule[n][i],'11:00'));const at1330=active.filter(n=>at(w.schedule[n][i],'13:30'));const at1630=active.filter(n=>at(w.schedule[n][i],'16:29'));const at17=active.filter(n=>at(w.schedule[n][i],'16:59'));const close=active.filter(n=>at(w.schedule[n][i],'20:29'));return{active,at11,at1330,at1630,at17,close}}
function validateMonth(w){const errors=[],warnings=[];if(!w?.dates?.length||!w.schedule)return{errors:['Turnazione mensile non valida'],warnings};
 // Continuità giorni lavorati, includendo eventuale periodo pubblicato precedente.
 for(const n of NAMES){let streak=0;const prev=official.weeks?.filter(x=>String(x.dates?.at(-1)||'')<w.dates[0]).sort((a,b)=>String(a.dates.at(-1)).localeCompare(String(b.dates.at(-1)))).at(-1);if(prev){for(let j=prev.dates.length-1;j>=0;j--){if(works(prev.schedule?.[n]?.[j]))streak++;else break}}
  for(let i=0;i<w.dates.length;i++){if(works(w.schedule[n][i])){streak++;if(streak>6)errors.push(`${n}: oltre 6 giorni consecutivi al ${fmtDate(w.dates[i])}`)}else streak=0}}
 w.dates.forEach((date,i)=>{const d=new Date(date+'T12:00:00'),dow=d.getDay(),stats=dayStats(w,i);
  if(dow===0){const resp=stats.active.filter(n=>RESPONSIBILI.includes(n));const ops=stats.active.filter(n=>OPERATIVI.includes(n));if(resp.length!==1)errors.push(`${fmtDate(date)}: domenica deve esserci 1 responsabile`);if(resp[0]!==respSunday(d))errors.push(`${fmtDate(date)}: responsabile domenicale errato, previsto ${respSunday(d)}`);if(ops.length!==3)errors.push(`${fmtDate(date)}: domenica devono lavorare 3 operativi`);const crew=opsSundayCrew(d);for(const n of ops)if(!crew.includes(n))errors.push(`${fmtDate(date)}: ${n} fuori rotazione domenicale`);for(const n of stats.active)if(w.schedule[n][i]!=='08:00-13:00')errors.push(`${fmtDate(date)}: domenica ${n} deve fare 08:00-13:00`);return}
  const respActive=RESPONSIBILI.filter(n=>works(w.schedule[n][i]));const respRest=RESPONSIBILI.filter(n=>w.schedule[n][i]==='RIPOSO');if(respActive.length===3){const shifts=respActive.map(n=>w.schedule[n][i]);for(const need of ['06:30-13:30','10:00-17:00','13:30-20:30'])if(!shifts.includes(need))errors.push(`${fmtDate(date)}: manca responsabile ${need}`)}else if(respActive.length===2&&respRest.length===1){if(!respActive.some(n=>w.schedule[n][i]==='06:30-13:30'))errors.push(`${fmtDate(date)}: manca responsabile 06:30-13:30`);if(!respActive.some(n=>w.schedule[n][i]==='13:30-20:30'))errors.push(`${fmtDate(date)}: manca responsabile 13:30-20:30`)}else errors.push(`${fmtDate(date)}: numero responsabili non valido`);
  const morningCash=stats.active.filter(n=>(CASSA.includes(n)||SALA_CASSA.includes(n))&&at(w.schedule[n][i],'08:00'));if(!morningCash.length)errors.push(`${fmtDate(date)}: manca cassa mattina`);
  const salaMorning=stats.active.filter(n=>SALA.includes(n)&&at(w.schedule[n][i],'08:00'));if(salaMorning.length<2)errors.push(`${fmtDate(date)}: meno di 2 persone sala al mattino`);if(!stats.active.some(n=>SALA.includes(n)&&begins(w.schedule[n][i],'06:30')))errors.push(`${fmtDate(date)}: manca una persona sala alle 06:30`);
  const aftCash=stats.active.filter(n=>(CASSA.includes(n)||SALA_CASSA.includes(n))&&at(w.schedule[n][i],'14:00'));if(!aftCash.length)errors.push(`${fmtDate(date)}: manca copertura cassa pomeriggio`);
  if(stats.at11.length<5)warnings.push(`${fmtDate(date)}: solo ${stats.at11.length} persone alle 11:00 (obiettivo 5)`);
  const peak=[1,3,4].includes(dow);const overlap=peak?stats.at1630:stats.at17;if(overlap.length<(peak?5:4))warnings.push(`${fmtDate(date)}: fascia 13:30-${peak?'16:30':'17:00'} sotto obiettivo (${overlap.length}/${peak?5:4})`);
  if(stats.close.length<4)warnings.push(`${fmtDate(date)}: chiusura in ${stats.close.length} invece di 4 preferite`);if(!stats.close.some(n=>RESPONSIBILI.includes(n)))errors.push(`${fmtDate(date)}: manca responsabile in chiusura`);
 });
 // Riposo infrasettimanale obbligatorio per chi lavora domenica, prima della domenica.
 for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()!==0)continue;const workers=[respSunday(d),...opsSundayCrew(d)];for(const n of workers){const s=new Date(d);s.setDate(s.getDate()-6);const from=iso(s),had=w.dates.some((x,j)=>x>=from&&x< w.dates[i]&&w.schedule[n][j]==='RIPOSO');if(!had)errors.push(`${n}: lavora domenica ${fmtDate(w.dates[i])} senza riposo infrasettimanale precedente`)}}
 return{errors:[...new Set(errors)],warnings:[...new Set(warnings)]}}
function audit5(w){const runs=[];for(let k=0;k<5;k++)runs.push(validateMonth(w));return{runs,final:runs[4],ok:runs.every(r=>r.errors.length===0)}}
function render(used=[]){const audit=audit5(draft),e=audit.final.errors,wr=audit.final.warnings,days=draft.dates.length;localStorage.setItem('tm_planner_draft',JSON.stringify({week:draft,issues:e,warnings:wr,audits:audit.runs.map(x=>({errors:x.errors.length,warnings:x.warnings.length})),createdAt:new Date().toISOString()}));const headers=draft.dates.map(x=>{const d=new Date(x+'T12:00:00');return`<div class="cell head ${d.getDay()===0?'sun':''}">${fmtDate(x).split(' ')[0]}<br>${d.getDate()}</div>`}).join('');const rows=NAMES.map(n=>`<div class="cell name">${esc(n)}</div>${draft.schedule[n].map((s,i)=>`<div class="cell ${new Date(draft.dates[i]+'T12:00:00').getDay()===0?'sun':''} ${OFF.has(s)?'rest':''}">${esc(s)}</div>`).join('')}`).join('');app.innerHTML=`<div class="app-shell"><div class="brandbar"></div><main class="nt"><div class="nt-head"><a href="index.html">‹ Home</a><strong>Turni mensili</strong><span></span></div><section class="card"><h2>${esc(draft.label)}</h2><div class="legend">Gruppo unico · 9 operativi + 3 responsabili · domeniche a rotazione · controllo continuo dei riposi.</div>${used.length?`<div class="legend">Richieste accettate applicate: ${used.length}</div>`:''}</section><section class="card"><h3>Controllo completo × 5</h3><div class="${e.length?'statusbad':'statusok'}">${e.length?`❌ ${e.length} errori bloccanti`:'✓ 5 controlli consecutivi completati senza errori bloccanti'}</div>${wr.length?`<div class="statuswarn">⚠️ ${wr.length} preferenze da migliorare (copertura 11:00 / fascia centrale / chiusura). Non sono errori bloccanti.</div>`:''}<div class="checks">${audit.runs.map((r,i)=>`<div><b>Controllo ${i+1}:</b> ${r.errors.length} errori · ${r.warnings.length} preferenze</div>`).join('')}</div></section><section class="card"><div class="month-grid"><div class="month-table" style="--days:${days}"><div class="cell head"></div>${headers}${rows}</div></div></section><div class="actions">${e.length?'<button class="publish" disabled>Correggere gli errori prima di pubblicare</button>':'<button class="publish" id="publish">Pubblica mese completo</button>'}</div></main></div>`;document.getElementById('publish')?.addEventListener('click',publish)}
async function publish(){const audit=audit5(draft);if(!audit.ok)return alert('La turnazione non supera i 5 controlli completi.');const data=structuredClone(official||{weeks:[]});data.weeks=(data.weeks||[]).filter(x=>!(x.period==='month'&&x.year===draft.year&&x.month===draft.month));data.weeks.push(draft);data.weeks.sort((a,b)=>String(a.dates?.[0]).localeCompare(String(b.dates?.[0])));data.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());try{await api('save_schedule',{method:'POST',body:{data}});localStorage.removeItem('tm_planner_draft');alert('Mese pubblicato dopo 5 controlli completi.');location.href='index.html'}catch(e){alert(e.message)}}
async function boot(){if(!u)return;try{const s=await api('get_schedule');official=s.data&&Array.isArray(s.data.weeks)?s.data:{weeks:[]};try{requests=(await api('list_requests')).requests||[]}catch{}let[y,m]=nextTargetMonth();[y,m]=normalizeYM(y,m);draft=buildMonth(y,m);const used=applyAccepted(draft);render(used)}catch(e){app.innerHTML=`<div class="error" style="margin:20px">${esc(e.message)}</div>`}}
boot();