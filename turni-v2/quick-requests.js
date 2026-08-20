(()=>{
'use strict';
const API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-api';
const PEOPLE=['Umberto','Fabio','Emanuele','Stefania B','Stefania F','Romina','Giada','Giuliano','Manuel','Daniele','Paolo','Marco'];
const SHIFTS=['06:30-13:30','07:00-12:00','07:00-12:30','07:00-13:00','07:00-13:30','07:00-14:00','07:00-14:30','07:00-15:00','07:00-15:30','08:00-14:00','08:00-15:00','09:00-15:00','09:00-16:00','10:00-16:00','10:00-17:00','11:00-16:00','11:00-17:00','11:00-18:00','12:00-18:00','12:30-19:00','13:00-19:30','13:30-20:00','13:30-20:30','14:00-20:00','14:00-20:30','14:30-20:30','15:00-20:00','15:30-20:30','16:00-20:00','16:30-20:30','07:00-13:00 / 17:00-20:00','07:00-13:00 / 17:00-20:30'];
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot',"'":'&#39;'}[c]));
const token=()=>localStorage.getItem('tm2_token')||'';
const user=()=>{try{return JSON.parse(localStorage.getItem('tm2_user')||'null')}catch{return null}};
async function call(action,{method='GET',body}={}){const r=await fetch(`${API}?action=${encodeURIComponent(action)}`,{method,headers:{'Content-Type':'application/json',...(token()?{Authorization:`Bearer ${token()}`}:{})},body:body?JSON.stringify(body):undefined});const d=await r.json().catch(()=>({error:'Risposta non valida'}));if(!r.ok)throw new Error(d.error||'Errore');return d}
async function createRequest(body){return call('admin_create_request',{method:'POST',body})}
function selectedStart(){return document.getElementById('startDate')?.value||''}
function ensureCompactCss(){if(document.getElementById('qrCompactCss'))return;const s=document.createElement('style');s.id='qrCompactCss';s.textContent=`
body[data-qr-generate="1"] .shell>.hero{padding-top:12px!important;padding-bottom:8px!important;margin-bottom:7px!important}
body[data-qr-generate="1"] .shell>.hero h1{font-size:23px!important;margin-bottom:3px!important}
body[data-qr-generate="1"] .shell>.hero p{margin:0!important}
body[data-qr-generate="1"] .shell>.grid{gap:7px!important}
body[data-qr-generate="1"] .shell .card{padding:10px!important}
body[data-qr-generate="1"] .shell .card h2{margin:0 0 7px!important;font-size:17px!important}
body[data-qr-generate="1"] .shell .field{margin-bottom:6px!important}
body[data-qr-generate="1"] .shell .field label{margin-bottom:2px!important}
body[data-qr-generate="1"] .shell input,body[data-qr-generate="1"] .shell select{min-height:36px!important;padding:6px 8px!important}
#quickRequestsPanel{margin:0 0 8px!important;padding:9px!important}
#quickRequestsPanel .qr-title{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:6px}
#quickRequestsPanel .qr-title h2{margin:0!important;font-size:16px!important}
#qrUnifiedWrap{max-height:210px;overflow:auto;border:1px solid rgba(120,120,120,.18);border-radius:9px}
#qrUnifiedTable{width:100%;border-collapse:collapse;font-size:12px;table-layout:auto}
#qrUnifiedTable th{position:sticky;top:0;z-index:2;background:var(--card,#fff);text-align:left;padding:6px 7px;border-bottom:1px solid rgba(120,120,120,.22);white-space:nowrap}
#qrUnifiedTable td{padding:6px 7px;border-bottom:1px solid rgba(120,120,120,.12);vertical-align:middle}
#qrUnifiedTable tr:last-child td{border-bottom:0}
#qrUnifiedTable th:last-child,#qrUnifiedTable td:last-child{position:sticky;right:0;background:var(--card,#fff);z-index:3;text-align:right;box-shadow:-8px 0 10px -12px #000}
.qr-kind{font-weight:800;white-space:nowrap}.qr-kind.abs{color:#b05b00}.qr-kind.req{color:#075daf}
.qr-mini-remove{padding:5px 8px!important;font-size:11px!important;white-space:nowrap;display:inline-block!important;visibility:visible!important;opacity:1!important}
#qrQuickAdd{margin-top:7px}
#qrQuickAdd summary{cursor:pointer;font-weight:800;font-size:13px;padding:3px 1px;user-select:none}
#quickRequestsPanel .qr-add-grid{display:grid;grid-template-columns:1fr 1fr;gap:7px;margin-top:7px}
#quickRequestsPanel .qr-box{padding:8px!important}
#quickRequestsPanel .qr-box h3{font-size:14px;margin:0 0 6px!important}
#quickRequestsPanel .formrow{gap:5px!important}
#quickRequestsPanel .btn{padding:6px 9px!important}
@media(max-width:700px){
 #qrUnifiedWrap{max-height:190px;overflow-y:auto;overflow-x:hidden}
 #qrUnifiedTable{font-size:11px;table-layout:fixed}
 #qrUnifiedTable th,#qrUnifiedTable td{padding:6px 4px;overflow:hidden;text-overflow:ellipsis}
 #qrUnifiedTable th:nth-child(1),#qrUnifiedTable td:nth-child(1){width:28%}
 #qrUnifiedTable th:nth-child(2),#qrUnifiedTable td:nth-child(2){width:18%}
 #qrUnifiedTable th:nth-child(3),#qrUnifiedTable td:nth-child(3){width:24%}
 #qrUnifiedTable th:nth-child(4),#qrUnifiedTable td:nth-child(4){display:none}
 #qrUnifiedTable th:nth-child(5),#qrUnifiedTable td:nth-child(5){width:30%;position:static;box-shadow:none;text-align:right}
 #qrUnifiedTable .qr-mini-remove{font-size:10px!important;padding:5px 6px!important}
 #quickRequestsPanel .qr-add-grid{grid-template-columns:1fr}
}
`;document.head.appendChild(s)}
function reqRow(r){const k=String(r.kind||'').toUpperCase();const detail=k==='TURNO'?(r.wanted_shift||''):'—';return `<tr><td><b>${esc(r.employee_name)}</b></td><td><span class="qr-kind req">${esc(k)}</span></td><td>${esc(r.request_date||'')}</td><td>${esc(detail)}</td><td><button class="btn danger qr-mini-remove" type="button" data-rm-request="${r.id}">Rimuovi</button></td></tr>`}
function absRow(a){const from=a.date_from||'',to=a.date_to||from,period=from===to?from:`${from} → ${to}`;return `<tr><td><b>${esc(a.employee_name)}</b></td><td><span class="qr-kind abs">${esc(String(a.absence_type||'').toUpperCase())}</span></td><td>${esc(period)}</td><td>Assenza programmata</td><td><button class="btn danger qr-mini-remove" type="button" data-rm-absence="${a.id}">Rimuovi</button></td></tr>`}
async function renderUnified(){const body=document.getElementById('qrUnifiedBody');if(!body)return;try{const [rq,ab]=await Promise.all([call('my_requests'),call('absences')]);const reqs=(rq.requests||[]).filter(r=>r.status==='ACCETTATA'&&['RIPOSO','TURNO'].includes(String(r.kind||'').toUpperCase()));const abs=(ab.absences||[]).filter(a=>['FERIE','MALATTIA','PERMESSO'].includes(String(a.absence_type||'').toUpperCase()));const rows=[...abs.map(a=>({date:a.date_from||'',html:absRow(a)})),...reqs.map(r=>({date:r.request_date||'',html:reqRow(r)}))].sort((a,b)=>a.date.localeCompare(b.date));body.innerHTML=rows.length?rows.map(x=>x.html).join(''):'<tr><td colspan="5" style="text-align:center;padding:10px;opacity:.7">Nessuna assenza o richiesta attiva.</td></tr>';body.querySelectorAll('[data-rm-request]').forEach(b=>b.addEventListener('click',async()=>{if(!confirm('Rimuovere questa richiesta dai vincoli dei nuovi turni?'))return;b.disabled=true;try{await call('resolve_request',{method:'POST',body:{id:Number(b.dataset.rmRequest),status:'RIFIUTATA',reply:'Richiesta rimossa dai nuovi turni da Eurospin.'}});await renderUnified()}catch(e){alert(e.message);b.disabled=false}}));body.querySelectorAll('[data-rm-absence]').forEach(b=>b.addEventListener('click',async()=>{if(!confirm('Rimuovere questa assenza programmata?'))return;b.disabled=true;try{await call('delete_absence',{method:'POST',body:{id:Number(b.dataset.rmAbsence)}});await renderUnified()}catch(e){alert(e.message);b.disabled=false}}))}catch(e){body.innerHTML=`<tr><td colspan="5"><div class="notice error">${esc(e.message)}</div></td></tr>`}}
function panel(){const section=document.createElement('section');section.id='quickRequestsPanel';section.className='card';const options=PEOPLE.map(n=>`<option value="${esc(n)}">${esc(n)}</option>`).join('');const shifts=SHIFTS.map(s=>`<option value="${esc(s)}">${esc(s)}</option>`).join('');section.innerHTML=`<div class="qr-title"><h2>📋 Assenze e richieste attive</h2></div><div id="qrUnifiedWrap"><table id="qrUnifiedTable"><thead><tr><th>Dipendente</th><th>Tipo</th><th>Data / periodo</th><th>Dettaglio</th><th>Azione</th></tr></thead><tbody id="qrUnifiedBody"><tr><td colspan="5">Caricamento…</td></tr></tbody></table></div><details id="qrQuickAdd"><summary>＋ Aggiungi richiesta RIPOSO / TURNO</summary><div class="qr-add-grid"><div class="item qr-box"><h3>🛌 RIPOSO</h3><div class="formrow"><div class="field"><label>Dipendente</label><select id="qrRestPerson">${options}</select></div><div class="field"><label>Giorno</label><input id="qrRestDate" type="date" value="${esc(selectedStart())}"></div></div><button class="btn blue" id="qrAddRest" type="button">Aggiungi</button><div id="qrRestMsg"></div></div><div class="item qr-box"><h3>🕒 TURNO</h3><div class="formrow"><div class="field"><label>Dipendente</label><select id="qrShiftPerson">${options}</select></div><div class="field"><label>Giorno</label><input id="qrShiftDate" type="date" value="${esc(selectedStart())}"></div></div><div class="field"><label>Turno</label><select id="qrShiftValue">${shifts}</select></div><button class="btn blue" id="qrAddShift" type="button">Aggiungi</button><div id="qrShiftMsg"></div></div></div></details>`;return section}
function msg(id,text,err=false){const m=document.getElementById(id);if(m)m.innerHTML=`<div class="notice ${err?'error':''}" style="margin-top:5px;padding:5px 7px">${esc(text)}</div>`}
async function addRest(){const b=document.getElementById('qrAddRest'),employeeName=document.getElementById('qrRestPerson')?.value,requestDate=document.getElementById('qrRestDate')?.value;if(!requestDate)return msg('qrRestMsg','Seleziona il giorno.',true);b.disabled=true;try{await createRequest({kind:'RIPOSO',employeeName,requestDate});msg('qrRestMsg','Salvato.');await renderUnified()}catch(e){msg('qrRestMsg',e.message,true)}finally{b.disabled=false}}
async function addShift(){const b=document.getElementById('qrAddShift'),employeeName=document.getElementById('qrShiftPerson')?.value,requestDate=document.getElementById('qrShiftDate')?.value,wantedShift=document.getElementById('qrShiftValue')?.value;if(!requestDate)return msg('qrShiftMsg','Seleziona il giorno.',true);b.disabled=true;try{await createRequest({kind:'TURNO',employeeName,requestDate,wantedShift});msg('qrShiftMsg','Salvato.');await renderUnified()}catch(e){msg('qrShiftMsg',e.message,true)}finally{b.disabled=false}}
let busy=false;
function hideDuplicateAbsenceCard(){for(const el of document.querySelectorAll('.card,h2,h3')){const txt=(el.textContent||'').trim().toLowerCase();if(txt.includes('assenze programmate')){const card=el.classList?.contains('card')?el:el.closest('.card');if(card&&card.id!=='quickRequestsPanel')card.style.display='none'}}}
function mount(){const on=location.hash==='#generate'&&user()?.role==='admin';document.body.dataset.qrGenerate=on?'1':'0';if(!on||busy||document.getElementById('quickRequestsPanel'))return;const gen=document.getElementById('doGenerate');if(!gen)return;busy=true;try{ensureCompactCss();hideDuplicateAbsenceCard();const cards=[...document.querySelectorAll('.shell > .grid, .shell .grid')];const target=cards.find(g=>g.querySelector('#doGenerate'))||gen.closest('.grid');if(!target)return;target.insertAdjacentElement('beforebegin',panel());document.getElementById('qrAddRest')?.addEventListener('click',addRest);document.getElementById('qrAddShift')?.addEventListener('click',addShift);renderUnified()}finally{busy=false}}
const obs=new MutationObserver(()=>{if(location.hash==='#generate')setTimeout(()=>{mount();hideDuplicateAbsenceCard()},40)});obs.observe(document.documentElement,{childList:true,subtree:true});window.addEventListener('hashchange',()=>setTimeout(mount,60));setTimeout(mount,300);
})();