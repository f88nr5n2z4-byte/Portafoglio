(()=>{
'use strict';
const USERS={StefaniaF:{password:'01',display:'Stefania F',employee:'Stefania F'},Romina:{password:'02',display:'Romina',employee:'Romina'},StefaniaB:{password:'03',display:'Stefania B',employee:'Stefania B'},Giada:{password:'04',display:'Giada',employee:'Giada'},Giuliano:{password:'05',display:'Giuliano',employee:'Giuliano'},Daniele:{password:'06',display:'Daniele',employee:'Daniele'},Paolo:{password:'07',display:'Paolo',employee:'Paolo'},Manuel:{password:'08',display:'Manuel',employee:'Manuel'},Eurospin:{password:'00',display:'Eurospin',admin:true}};
const ROLES={'Umberto':'Responsabile','Stefania B':'Cassa','Giada':'Cassa','Giuliano':'Sala','Daniele':'Sala','Manuel':'Sala','Fabio':'Responsabile','Emanuele':'Responsabile / Sala','Romina':'Cassa','Stefania F':'Cassa','Paolo':'Sala','Marco':'Jolly / Sala'};
const TARGETS={'Giada':30,'Marco':16},CASH=new Set(['Stefania B','Giada','Romina','Stefania F']),RESP=new Set(['Umberto','Fabio','Emanuele']),SALA=new Set(['Giuliano','Daniele','Manuel','Emanuele','Paolo','Marco']),ABSENCES=new Set(['RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—']);
const SHIFT_OPTIONS=['06:30-13:30','07:00-14:00','09:00-14:00','10:00-17:00','10:00-18:00','10:00-19:00','11:00-18:00','11:00-20:00','11:00-20:30','12:00-20:00','12:00-20:30','13:30-20:30','14:00-20:00','14:00-20:30','16:00-20:00','16:30-20:30','07:00-13:00 / 17:00-20:00','07:00-13:00 / 17:00-20:30','06:30-13:30 / 17:00-20:30','08:00-13:00','RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—'];
const API_URL='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-api',NO_PUSH_URL='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-write-no-push';
const getSession=()=>{try{return JSON.parse(localStorage.getItem('tm_session')||'null')}catch{return null}};
function setSession(u){localStorage.setItem('tm_session',JSON.stringify(u))}
function requireUser(admin=false){const u=getSession();if(!u){location.replace('index.html');return null}if(admin&&!u.admin){location.replace('index.html');return null}return u}
function logout(){localStorage.removeItem('tm_session');location.href='index.html'}
async function api(action,{method='GET',body=null}={}){const u=getSession();if(!u)throw new Error('Sessione scaduta');const url=(action==='create_request'||action==='save_schedule'?NO_PUSH_URL:API_URL);let r;try{r=await fetch(`${url}?action=${encodeURIComponent(action)}`,{method,headers:{'Content-Type':'application/json','x-user':u.key,'x-pass':u.password},body:body?JSON.stringify(body):null})}catch{throw new Error('Connessione non riuscita. Riprova.')}const d=await r.json().catch(()=>({error:'Risposta non valida'}));if(!r.ok)throw new Error(d.error||'Errore di connessione');return d}
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function iso(d){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`}
function nextMonday(){const d=new Date();d.setHours(12,0,0,0);let k=(8-d.getDay())%7;if(!k)k=7;d.setDate(d.getDate()+k);return iso(d)}
function fmtDate(x){return new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(x+'T12:00:00'))}
function formatDateTime(x){return new Intl.DateTimeFormat('it-IT',{dateStyle:'short',timeStyle:'short'}).format(new Date(x))}
function hm(t){const[a,b]=String(t).split(':').map(Number);return a*60+b}
function spans(s){if(!s||ABSENCES.has(String(s).trim().toUpperCase()))return[];try{return String(s).split('/').map(x=>x.trim()).map(x=>{const[a,b]=x.split('-').map(v=>v.trim());return[hm(a),hm(b)]}).filter(([a,b])=>Number.isFinite(a)&&Number.isFinite(b)&&b>a)}catch{return[]}}
function shiftHours(s){return spans(s).reduce((z,[a,b])=>z+(b-a)/60,0)}
function weekHours(w,n){return(w.schedule?.[n]||[]).reduce((z,s)=>z+shiftHours(s),0)}
function target(n){return TARGETS[n]||40}
function statusBadge(s){const map={'DA VALUTARE':['Da valutare','pending'],'ACCETTATA':['Accettata','accepted'],'RIFIUTATA':['Rifiutata','rejected']},x=map[s]||map['DA VALUTARE'];return `<span class="reqstatus ${x[1]}">${x[0]}</span>`}
async function loadSchedule(){try{const r=await api('get_schedule');if(r.data&&Array.isArray(r.data.weeks))return r.data}catch{}return fetch('schedule.json').then(r=>r.json())}
function displayMode(){const saved=localStorage.getItem('tm_display_mode');return saved==='pc'||saved==='phone'?saved:(matchMedia('(min-width:900px)').matches?'pc':'phone')}
function applyDisplayMode(mode=displayMode()){localStorage.setItem('tm_display_mode',mode);document.documentElement.dataset.displayMode=mode;document.body?.classList.toggle('mode-pc',mode==='pc');document.body?.classList.toggle('mode-phone',mode==='phone');return mode}
function installDisplayToggle(){applyDisplayMode();if(document.getElementById('displayModeBtn'))return;const b=document.createElement('button');b.id='displayModeBtn';b.type='button';b.className='displayModeBtn';b.textContent=displayMode()==='pc'?'💻':'📱';b.onclick=()=>{const m=displayMode()==='pc'?'phone':'pc';applyDisplayMode(m);b.textContent=m==='pc'?'💻':'📱'};document.body.appendChild(b)}
function warm(urls){const run=()=>urls.forEach(u=>fetch(u,{cache:'force-cache'}).catch(()=>{}));'requestIdleCallback'in window?requestIdleCallback(run,{timeout:1500}):setTimeout(run,500)}
Object.assign(window,{USERS,ROLES,TARGETS,CASH,RESP,SALA,ABSENCES,SHIFT_OPTIONS,API_URL,getSession,setSession,requireUser,logout,api,esc,fmtDate,formatDateTime,hm,spans,shiftHours,weekHours,target,statusBadge,loadSchedule});
window.TMAPP={USERS,ROLES,API_URL,getSession,setSession,requireUser,logout,api,esc,iso,nextMonday,fmtDate,formatDateTime,hm,spans,shiftHours,weekHours,target,statusBadge,loadSchedule,displayMode,applyDisplayMode,installDisplayToggle,warm};
})();