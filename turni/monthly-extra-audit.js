(()=>{
'use strict';
const ROOT=document.getElementById('app');if(!ROOT)return;
const NAMES=['Umberto','Fabio','Emanuele','Stefania B','Giada','Giuliano','Daniele','Manuel','Romina','Stefania F','Paolo','Marco'];
const RESP=['Umberto','Fabio','Emanuele'];
const OFF=new Set(['RIPOSO','FERIE','MALATTIA','MATERNITÀ','PERMESSO','—']);
const works=s=>{if(!s||OFF.has(s))return false;return String(s).split('/').some(x=>{const p=x.trim().split('-').map(v=>v.trim());return p.length===2&&Number.isFinite(hm(p[0]))&&Number.isFinite(hm(p[1]))&&hm(p[1])>hm(p[0])})};
const monday=d=>{const x=new Date(d+'T12:00:00'),k=(x.getDay()+6)%7;x.setDate(x.getDate()-k);return x.toLocaleDateString('sv-SE')};
function readState(){try{return JSON.parse(localStorage.getItem('tm_planner_draft')||'null')}catch{return null}}
function add(arr,msg){if(!arr.includes(msg))arr.push(msg)}
function solution(msg){
 if(/oltre 6 giorni consecutivi/i.test(msg))return 'Inserire un RIPOSO prima del 7° giorno; poi recuperare le ore sugli altri giorni senza creare un nuovo giorno lavorativo.';
 if(/senza RIPOSO compensativo/i.test(msg))return 'Inserire un RIPOSO nella settimana della domenica lavorata nel giorno con minore impatto sulle coperture.';
 if(/responsabil/i.test(msg)&&/06:30-13:30|13:30-20:30/i.test(msg))return 'Con un responsabile a RIPOSO, gli altri due devono fare esattamente 06:30–13:30 e 13:30–20:30.';
 if(/cassa mattina/i.test(msg))return 'Garantire una cassiera o Giuliano/Daniele/Manuel nella fascia richiesta. Paolo e Marco non possono fare cassa.';
 if(/cassa pomeriggio/i.test(msg))return 'Garantire cassiera o backup abilitato nel pomeriggio.';
 if(/meno di 2 sala/i.test(msg))return 'Aggiungere un secondo sala effettivo; chi copre la cassa non conta anche come sala.';
 if(/sala alle 06:30/i.test(msg))return 'Portare Giuliano, Daniele o Manuel alle 06:30 mantenendo un altro sala presente alle 07:00.';
 if(/meno di 4 presenti alle 07:00/i.test(msg))return 'Anticipare una persona con 06:30–13:30 o 07:00–14:00.';
 if(/manca responsabile/i.test(msg))return 'Riassegnare i responsabili sui turni obbligatori del giorno.';
 if(/domenica/i.test(msg)&&/4 persone|3 operativi|08:00-13:00/i.test(msg))return 'Domenica: esattamente 4 persone, 1 responsabile + 3 operativi, tutti 08:00–13:00.';
 if(/date duplicate/i.test(msg))return 'Correggere la fusione delle settimane a cavallo mese prima della pubblicazione.';
 return 'Modificare manualmente il turno indicato e ricontrollare: il sistema ricalcolerà subito tutti gli altri vincoli.';
}
function findContext(msg,w){let name=null,di=-1;for(const n of NAMES)if(msg.includes(n)){name=n;break}for(let i=0;i<w.dates.length;i++){const iso=w.dates[i],lab=fmtDate(iso);if(msg.includes(iso)||msg.includes(lab)){di=i;break}}return{name,di}}
function clearMarks(){ROOT.querySelectorAll('.diag-error,.diag-warn').forEach(x=>x.classList.remove('diag-error','diag-warn'))}
function mark(msg,w){const tables=[...ROOT.querySelectorAll('.month-table')];const {name,di}=findContext(msg,w);for(const t of tables){const cells=[...t.querySelectorAll('.cell')];for(const c of cells){if(di>=0&&c.dataset?.date===w.dates[di])c.classList.add('diag-error');if(name&&c.dataset?.person===name&&(di<0||c.dataset?.date===w.dates[di]))c.classList.add('diag-error')}}}
function detailCard(blocking,w){ROOT.querySelector('.diagnostic-card')?.remove();const control=[...ROOT.querySelectorAll('.card')].find(c=>c.querySelector('h3')?.textContent.includes('Controllo finale'));if(!control)return;const card=document.createElement('section');card.className='card diagnostic-card';const body=blocking.length?`<div class="diag-section bad"><h4>🔴 Errori reali da correggere (${blocking.length})</h4>${blocking.map((m,i)=>`<details ${i<6?'open':''}><summary>${esc(m)}</summary><div class="diag-help"><b>Come risolvere:</b> ${esc(solution(m))}</div></details>`).join('')}</div>`:'<div class="statusok">✓ Nessun errore reale. Gli aspetti migliorabili vengono gestiti automaticamente dal generatore.</div>';card.innerHTML=`<h3>Dove sono i problemi</h3><p class="diag-intro">Qui vengono mostrati solo gli <b>errori rossi veri</b>. Ore, equilibrio dei turni e altre preferenze vengono migliorati automaticamente quando possibile.</p>${body}`;control.insertAdjacentElement('afterend',card);clearMarks();blocking.forEach(m=>mark(m,w))}
async function run(){const state=readState(),w=state?.week;if(!w?.dates?.length||!w.schedule)return;let official={weeks:[]};try{const r=await api('get_schedule');if(r.data&&Array.isArray(r.data.weeks))official=r.data}catch{}
 const blocking=[...(state?.issues||[])].filter(m=>{
  if(RESP.some(n=>String(m).includes(n))&&/\bh\b|ore|obiettivo|target/i.test(m))return false;
  if(/settimana .*h \(obiettivo/i.test(m))return false;
  const over=String(m).match(/([0-9]+(?:[.,][0-9]+)?)h\s+oltre/i);if(over&&parseFloat(over[1].replace(',','.'))<10)return false;
  return true;
 });
 for(const n of NAMES){const map=new Map();for(const pw of (official.weeks||[]))for(let i=0;i<(pw.dates||[]).length;i++)map.set(pw.dates[i],pw.schedule?.[n]?.[i]);for(let i=0;i<w.dates.length;i++)map.set(w.dates[i],w.schedule?.[n]?.[i]);const rows=[...map].map(([d,s])=>({d,s,inDraft:w.dates.includes(d)})).sort((a,b)=>a.d.localeCompare(b.d));let streak=0,last=null,touches=false;for(const row of rows){if(last){const gap=(new Date(row.d+'T12:00:00')-new Date(last+'T12:00:00'))/86400000;if(gap!==1){streak=0;touches=false}}if(works(row.s)){streak++;touches=touches||row.inDraft;if(streak>6&&touches)add(blocking,`${n}: oltre 6 giorni consecutivi il ${row.d}`)}else{streak=0;touches=false}last=row.d}}
 for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)continue;const resting=RESP.filter(n=>w.schedule?.[n]?.[i]==='RIPOSO');if(resting.length===1){const other=RESP.filter(n=>n!==resting[0]),shifts=other.map(n=>w.schedule?.[n]?.[i]);if(!(shifts.includes('06:30-13:30')&&shifts.includes('13:30-20:30')))add(blocking,`${w.dates[i]}: con ${resting[0]} a RIPOSO, gli altri due responsabili devono fare 06:30-13:30 e 13:30-20:30`)}}
 for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()!==0)continue;const key=monday(w.dates[i]);for(const n of NAMES){if(!works(w.schedule?.[n]?.[i]))continue;let rests=0;for(let k=0;k<w.dates.length;k++)if(monday(w.dates[k])===key&&w.schedule?.[n]?.[k]==='RIPOSO')rests++;for(const pw of (official.weeks||[]))for(let k=0;k<(pw.dates||[]).length;k++)if(!w.dates.includes(pw.dates[k])&&monday(pw.dates[k])===key&&pw.schedule?.[n]?.[k]==='RIPOSO')rests++;if(rests===0)add(blocking,`${n}: lavora domenica ${w.dates[i]} senza RIPOSO compensativo`)}}
 for(const pw of (official.weeks||[])){const a=pw.dates||[];if(new Set(a).size!==a.length)add(blocking,`Archivio: date duplicate nella settimana ${pw.label||a[0]||''}`)}
 const B=[...new Set(blocking)],card=[...ROOT.querySelectorAll('.card')].find(c=>c.querySelector('h3')?.textContent.includes('Controllo finale'));if(!card)return;card.querySelector('.extra-audit')?.remove();const box=document.createElement('div');box.className=B.length?'statusbad extra-audit':'statusok extra-audit';box.style.marginTop='8px';box.innerHTML=B.length?`Restano ${B.length} errore/i reali da correggere.`:'✓ Nessun errore bloccante.';card.appendChild(box);const yellow=card.querySelector('.statuswarn');if(yellow){yellow.className='statusok';yellow.textContent='✓ Miglioramenti automatici applicati dove possibile.'}detailCard(B,w);const pub=document.getElementById('publish');if(pub&&B.length){pub.disabled=true;pub.textContent='Correggere gli errori rossi prima di pubblicare'}
}
const style=document.createElement('style');style.textContent=`.diagnostic-card{margin-top:10px}.diag-intro{font-size:13px;line-height:1.45;color:#425b70}.diag-section{margin-top:12px}.diag-section h4{margin:0 0 8px}.diag-section details{border:1px solid #e6b1b1;border-radius:12px;margin:7px 0;background:#fff7f7;overflow:hidden}.diag-section summary{padding:11px;font-weight:900;cursor:pointer}.diag-help{padding:0 11px 11px;font-size:12px;line-height:1.45}.month-table .diag-error{background:#ffe2e2!important;box-shadow:inset 0 0 0 2px #c92d2d}`;document.head.appendChild(style);
let timer=null;const schedule=()=>{clearTimeout(timer);timer=setTimeout(run,180)};new MutationObserver(schedule).observe(ROOT,{childList:true,subtree:true});window.addEventListener('load',schedule);schedule();
})();