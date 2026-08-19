(()=>{
'use strict';
const USERS={StefaniaF:{password:'01',display:'Stefania F',employee:'Stefania F'},Romina:{password:'02',display:'Romina',employee:'Romina'},StefaniaB:{password:'03',display:'Stefania B',employee:'Stefania B'},Giada:{password:'04',display:'Giada',employee:'Giada'},Giuliano:{password:'05',display:'Giuliano',employee:'Giuliano'},Daniele:{password:'06',display:'Daniele',employee:'Daniele'},Paolo:{password:'07',display:'Paolo',employee:'Paolo'},Manuel:{password:'08',display:'Manuel',employee:'Manuel'},Eurospin:{password:'00',display:'Eurospin',admin:true}};
const API_URL='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-api';
const getSession=()=>{try{return JSON.parse(localStorage.getItem('tm_session')||'null')}catch{return null}};
function requireUser(admin=false){const u=getSession();if(!u){location.replace('index.html');return null}if(admin&&!u.admin){location.replace('index.html');return null}return u}
async function api(action,{method='GET',body=null}={}){const u=getSession();if(!u)throw new Error('Sessione scaduta');const r=await fetch(`${API_URL}?action=${encodeURIComponent(action)}`,{method,headers:{'Content-Type':'application/json','x-user':u.key,'x-pass':u.password},body:body?JSON.stringify(body):null,cache:'no-store'});const d=await r.json().catch(()=>({error:'Risposta non valida'}));if(!r.ok)throw new Error(d.error||'Errore di connessione');return d}
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function iso(d){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`}
function nextMonday(){const d=new Date();d.setHours(12,0,0,0);let k=(8-d.getDay())%7;if(!k)k=7;d.setDate(d.getDate()+k);return iso(d)}
function displayMode(){const saved=localStorage.getItem('tm_display_mode');return saved==='pc'||saved==='phone'?saved:(matchMedia('(min-width:900px)').matches?'pc':'phone')}
function applyDisplayMode(mode=displayMode()){localStorage.setItem('tm_display_mode',mode);document.documentElement.dataset.displayMode=mode;document.body?.classList.toggle('mode-pc',mode==='pc');document.body?.classList.toggle('mode-phone',mode==='phone');return mode}
function installDisplayToggle(){applyDisplayMode();if(document.getElementById('displayModeBtn'))return;const b=document.createElement('button');b.id='displayModeBtn';b.type='button';b.className='displayModeBtn';b.textContent=displayMode()==='pc'?'💻':'📱';b.addEventListener('click',()=>{const m=displayMode()==='pc'?'phone':'pc';applyDisplayMode(m);b.textContent=m==='pc'?'💻':'📱'});document.body.appendChild(b)}
window.TMAPP={USERS,API_URL,getSession,requireUser,api,esc,iso,nextMonday,displayMode,applyDisplayMode,installDisplayToggle};
})();