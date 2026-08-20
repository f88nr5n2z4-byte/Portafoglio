(()=>{
'use strict';
const API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-api';
const PEOPLE=['Umberto','Fabio','Emanuele','Stefania B','Stefania F','Romina','Giada','Giuliano','Manuel','Daniele','Paolo','Marco'];
const SHIFTS=['06:30-13:30','07:00-12:00','07:00-12:30','07:00-13:00','07:00-13:30','07:00-14:00','07:00-14:30','07:00-15:00','07:00-15:30','08:00-14:00','08:00-15:00','09:00-15:00','09:00-16:00','10:00-16:00','10:00-17:00','11:00-16:00','11:00-17:00','11:00-18:00','12:00-18:00','12:30-19:00','13:00-19:30','13:30-20:00','13:30-20:30','14:00-20:00','14:00-20:30','14:30-20:30','15:00-20:00','15:30-20:30','16:00-20:00','16:30-20:30','07:00-13:00 / 17:00-20:00','07:00-13:00 / 17:00-20:30'];
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const token=()=>localStorage.getItem('tm2_token')||'';
const user=()=>{try{return JSON.parse(localStorage.getItem('tm2_user')||'null')}catch{return null}};
async function call(action,{method='GET',body}={}){const r=await fetch(`${API}?action=${encodeURIComponent(action)}`,{method,headers:{'Content-Type':'application/json',...(token()?{Authorization:`Bearer ${token()}`}:{})},body:body?JSON.stringify(body):undefined});const d=await r.json().catch(()=>({error:'Risposta non valida'}));if(!r.ok)throw new Error(d.error||'Errore');return d}
async function createRequest(body){return call('admin_create_request',{method:'POST',body})}
function selectedStart(){return document.getElementById('startDate')?.value||''}
function ensureCompactCss(){if(document.getElementById('qrCompactCss'))return;const s=document.createElement('style');s.id='qrCompactCss';s.textContent=`
body[data-qr-generate="1"] .shell>.hero{padding-top:14px!important;padding-bottom:10px!important;margin-bottom:8px!important}
body[data-qr-generate="1"] .shell>.hero h1{font-size:24px!important;margin-bottom:4px!important}
body[data-qr-generate="1"] .shell>.hero p{margin:0!important}
body[data-qr-generate="1"] .shell>.grid{gap:8px!important}
body[data-qr-generate="1"] .shell .card{padding:12px!important}
body[data-qr-generate="1"] .shell .card h2{margin:0 0 8px!important;font-size:18px!important}
body[data-qr-generate="1"] .shell .field{margin-bottom:7px!important}
body[data-qr-generate="1"] .shell .field label{margin-bottom:3px!important}
body[data-qr-generate="1"] .shell input,body[data-qr-generate="1"] .shell select{min-height:38px!important;padding:7px 9px!important}
body[data-qr-generate="1"] #quickRequestsPanel{margin-top:8px!important;padding:10px!important}
#qrActiveList{display:grid;gap:6px;margin:0 0 9px}
.qr-active{display:flex;align-items:center;gap:8px;padding:7px 9px;border:1px solid rgba(120,120,120,.18);border-radius:10px;background:rgba(120,120,120,.05)}
.qr-active-main{min-width:0;flex:1}.qr-active-main b{font-size:14px}.qr-active-main small{display:block;opacity:.75;margin-top:2px}.qr-remove{padding:6px 9px!important;white-space:nowrap}
#quickRequestsPanel .qr-title{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:6px}
#quickRequestsPanel .qr-title h2{margin:0!important}
#quickRequestsPanel .qr-help{font-size:12px;opacity:.72;margin:0 0 8px}
#quickRequestsPanel .qr-add-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
#quickRequestsPanel .qr-box{padding:9px!important}
#quickRequestsPanel .qr-box h3{font-size:15px;margin:0 0 7px!important}
#quickRequestsPanel .formrow{gap:6px!important}
#quickRequestsPanel .btn{padding:7px 10px!important}
@media(max-width:700px){#quickRequestsPanel .qr-add-grid{grid-template-columns:1fr}.qr-active{align-items:flex-start}.qr-remove{margin-left:auto}}
`;document.head.appendChild(s)}
function activeRow(r){const detail=r.kind==='TURNO'?`Turno ${esc(r.wanted_shift||'')}`:'Riposo';return `<div class="qr-active"><div class="qr-active-main"><b>${esc(r.employee_name)} · ${esc(detail)}</b><small>${esc(r.request_date||'')}</small></div><button class="btn danger qr-remove" type="button" data-qr-remove="${r.id}">Rimuovi</button></div>`}
async function renderActive(){const box=document.getElementById('qrActiveList');if(!box)return;try{const d=await call('my_requests');const active=(d.requests||[]).filter(r=>r.status==='ACCETTATA'&&['RIPOSO','TURNO'].includes(String(r.kind||'').toUpperCase()));box.innerHTML=active.length?active.map(activeRow).join(''):'<div class="notice" style="padding:7px 9px">Nessuna richiesta attiva.</div>';box.querySelectorAll('[data-qr-remove]').forEach(b=>b.addEventListener('click',async()=>{if(!confirm('Rimuovere questa richiesta dai vincoli dei nuovi turni?'))return;b.disabled=true;try{await call('resolve_request',{method:'POST',body:{id:Number(b.dataset.qrRemove),status:'RIFIUTATA',reply:'Richiesta rimossa dai nuovi turni da Eurospin.'}});await renderActive()}catch(e){alert(e.message);b.disabled=false}}))}catch(e){box.innerHTML=`<div class="notice error">${esc(e.message)}</div>`}}
function panel(){const section=document.createElement('section');section.id='quickRequestsPanel';section.className='card';const options=PEOPLE.map(n=>`<option value="${esc(n)}">${esc(n)}</option>`).join('');const shifts=SHIFTS.map(s=>`<option value="${esc(s)}">${esc(s)}</option>`).join('');section.innerHTML=`<div class="qr-title"><h2>📌 Richieste nuovi turni</h2></div><p class="qr-help">Le richieste qui sotto sono già accettate e vengono rispettate dal generatore.</p><div id="qrActiveList"><div class="notice" style="padding:7px 9px">Caricamento richieste…</div></div><div class="qr-add-grid"><div class="item qr-box"><h3>🛌 Aggiungi RIPOSO</h3><div class="formrow"><div class="field"><label>Dipendente</label><select id="qrRestPerson">${options}</select></div><div class="field"><label>Giorno</label><input id="qrRestDate" type="date" value="${esc(selectedStart())}"></div></div><button class="btn blue" id="qrAddRest" type="button">Aggiungi</button><div id="qrRestMsg"></div></div><div class="item qr-box"><h3>🕒 Aggiungi TURNO</h3><div class="formrow"><div class="field"><label>Dipendente</label><select id="qrShiftPerson">${options}</select></div><div class="field"><label>Giorno</label><input id="qrShiftDate" type="date" value="${esc(selectedStart())}"></div></div><div class="field"><label>Turno</label><select id="qrShiftValue">${shifts}</select></div><button class="btn blue" id="qrAddShift" type="button">Aggiungi</button><div id="qrShiftMsg"></div></div></div>`;return section}
function msg(id,text,err=false){const m=document.getElementById(id);if(m)m.innerHTML=`<div class="notice ${err?'error':''}" style="margin-top:6px;padding:6px 8px">${esc(text)}</div>`}
async function addRest(){const b=document.getElementById('qrAddRest'),employeeName=document.getElementById('qrRestPerson')?.value,requestDate=document.getElementById('qrRestDate')?.value;if(!requestDate)return msg('qrRestMsg','Seleziona il giorno.',true);b.disabled=true;try{await createRequest({kind:'RIPOSO',employeeName,requestDate});msg('qrRestMsg','Salvato.');await renderActive()}catch(e){msg('qrRestMsg',e.message,true)}finally{b.disabled=false}}
async function addShift(){const b=document.getElementById('qrAddShift'),employeeName=document.getElementById('qrShiftPerson')?.value,requestDate=document.getElementById('qrShiftDate')?.value,wantedShift=document.getElementById('qrShiftValue')?.value;if(!requestDate)return msg('qrShiftMsg','Seleziona il giorno.',true);b.disabled=true;try{await createRequest({kind:'TURNO',employeeName,requestDate,wantedShift});msg('qrShiftMsg','Salvato.');await renderActive()}catch(e){msg('qrShiftMsg',e.message,true)}finally{b.disabled=false}}
let busy=false;
function mount(){const on=location.hash==='#generate'&&user()?.role==='admin';document.body.dataset.qrGenerate=on?'1':'0';if(!on||busy||document.getElementById('quickRequestsPanel'))return;const gen=document.getElementById('doGenerate');if(!gen)return;busy=true;try{ensureCompactCss();const cards=[...document.querySelectorAll('.shell > .grid, .shell .grid')];const target=cards.find(g=>g.querySelector('#doGenerate'))||gen.closest('.grid');if(!target)return;target.insertAdjacentElement('afterend',panel());document.getElementById('qrAddRest')?.addEventListener('click',addRest);document.getElementById('qrAddShift')?.addEventListener('click',addShift);renderActive()}finally{busy=false}}
const obs=new MutationObserver(()=>{if(location.hash==='#generate')setTimeout(mount,40)});obs.observe(document.documentElement,{childList:true,subtree:true});window.addEventListener('hashchange',()=>setTimeout(mount,60));setTimeout(mount,300);
})();