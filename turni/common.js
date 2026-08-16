const USERS={
  StefaniaF:{password:'01',display:'Stefania F',employee:'Stefania F'},
  Romina:{password:'02',display:'Romina',employee:'Romina'},
  StefaniaB:{password:'03',display:'Stefania B',employee:'Stefania B'},
  Giada:{password:'04',display:'Giada',employee:'Giada'},
  Giuliano:{password:'05',display:'Giuliano',employee:'Giuliano'},
  Daniele:{password:'06',display:'Daniele',employee:'Daniele'},
  Paolo:{password:'07',display:'Paolo',employee:'Paolo'},
  Manuel:{password:'08',display:'Manuel',employee:'Manuel'},
  Eurospin:{password:'00',display:'Eurospin',admin:true}
};
const ROLES={'Umberto':'Responsabile','Stefania B':'Cassa','Giada':'Cassa','Giuliano':'Sala','Daniele':'Sala','Manuel':'Sala','Fabio':'Responsabile','Emanuele':'Responsabile / Sala','Romina':'Cassa','Stefania F':'Cassa','Paolo':'Sala','Marco':'Jolly / Sala'};
const SHIFT_OPTIONS=['06:30-13:30','07:00-14:00','09:00-14:00','10:00-17:00','11:00-18:00','13:30-20:30','14:00-20:00','16:00-20:00','16:30-20:30','07:00-13:00 / 17:00-20:00','07:00-13:00 / 17:00-20:30','08:00-13:00','RIPOSO','FERIE','MATERNITÀ','—'];
const API_URL='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-api';
function getSession(){try{return JSON.parse(sessionStorage.getItem('tm_session')||'null')}catch{return null}}
function setSession(u){sessionStorage.setItem('tm_session',JSON.stringify(u))}
function logout(){sessionStorage.removeItem('tm_session');location.href='index.html'}
function requireUser(adminOnly=false){const u=getSession();if(!u){location.href='index.html';return null}if(adminOnly&&!u.admin){location.href='index.html';return null}return u}
function fmtDate(iso){return new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(iso+'T12:00:00'))}
function formatDateTime(iso){return new Intl.DateTimeFormat('it-IT',{dateStyle:'short',timeStyle:'short'}).format(new Date(iso))}
async function api(action,{method='GET',body=null}={}){
  const u=getSession();if(!u)throw new Error('Sessione scaduta');
  const res=await fetch(`${API_URL}?action=${encodeURIComponent(action)}`,{
    method,
    headers:{'Content-Type':'application/json','x-user':u.key,'x-pass':u.password},
    body:body?JSON.stringify(body):null,
    cache:'no-store'
  });
  const data=await res.json().catch(()=>({error:'Risposta non valida'}));
  if(!res.ok)throw new Error(data.error||'Errore di connessione');
  return data;
}
async function loadSchedule(){
  try{const r=await api('get_schedule');if(r.data&&Array.isArray(r.data.weeks)&&r.data.weeks.length)return r.data}catch(e){console.warn('Backend turni non disponibile',e)}
  return fetch('schedule.json',{cache:'no-store'}).then(r=>r.json());
}
function statusClass(s){return s==='RIPOSO'?'rest':s==='FERIE'?'holiday':s==='MATERNITÀ'?'maternity':'work'}
function esc(s){return String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]))}
