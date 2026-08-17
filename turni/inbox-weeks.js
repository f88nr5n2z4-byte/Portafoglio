(()=>{
 const MONTHS={gen:0,feb:1,mar:2,apr:3,mag:4,giu:5,lug:6,ago:7,set:8,ott:9,nov:10,dic:11};
 function requestDate(x){
  const q=parseShiftRequest(x);if(!q?.dateLabel)return null;
  const m=String(q.dateLabel).toLowerCase().match(/(?:lun|mar|mer|gio|ven|sab|dom)?\s*(\d{1,2})\s+([a-zà]+)/i);if(!m)return null;
  const mon=MONTHS[m[2].slice(0,3)];if(mon===undefined)return null;
  const base=x.created_at?new Date(x.created_at):new Date();let best=null,bestDiff=Infinity;
  for(const y of [base.getFullYear()-1,base.getFullYear(),base.getFullYear()+1]){const d=new Date(y,mon,+m[1],12);const diff=Math.abs(d-base);if(diff<bestDiff){best=d;bestDiff=diff}}
  return best;
 }
 function weekInfo(d){
  const day=d.getDay()||7,start=new Date(d);start.setDate(d.getDate()-day+1);start.setHours(12,0,0,0);const end=new Date(start);end.setDate(start.getDate()+6);
  const fmt=n=>String(n).padStart(2,'0');const key=`${start.getFullYear()}-${fmt(start.getMonth()+1)}-${fmt(start.getDate())}`;
  const sameMonth=start.getMonth()===end.getMonth();const month=n=>new Intl.DateTimeFormat('it-IT',{month:'long'}).format(n);
  const label=sameMonth?`${start.getDate()}–${end.getDate()} ${month(start)}`:`${start.getDate()} ${month(start)} – ${end.getDate()} ${month(end)}`;
  return{key,label,start};
 }
 function card(x){
  const quick=parseShiftRequest(x);
  if(mode==='open'&&quick)return `<article class="request-item open-request"><div class="request-meta">${esc(formatDateTime(x.created_at))} · <b>${esc(x.employee)}</b></div><div class="request-top">${statusBadge(x.status)} <span class="closed-badge" style="background:#ffd500;color:#003d7c">${esc(quick.type)}</span></div><div class="replybox"><small>${esc(quick.dateLabel)}</small><p><b>Attuale:</b> ${esc(quick.current)}<br><b>Richiesto:</b> ${esc(quick.wanted)}</p></div><a class="primary center" href="review-change.html?id=${x.id}" style="display:block;text-align:center">Visualizza Turnazione</a></article>`;
  return mode==='open'?`<article class="request-item open-request"><div class="request-meta">${esc(formatDateTime(x.created_at))} · <b>${esc(x.employee)}</b></div><div class="request-top">${statusBadge(x.status)}</div><p>${esc(x.message)}</p><div class="request-admin" style="display:grid;grid-template-columns:1fr 1fr;gap:8px"><button class="primary smallbtn" data-normal="${x.id}" data-status="ACCETTATA">Accetta</button><button class="secondary smallbtn" data-normal="${x.id}" data-status="RIFIUTATA">Rifiuta</button></div></article>`:`<article class="request-item closed-request"><div class="request-meta">${esc(formatDateTime(x.created_at))} · <b>${esc(x.employee)}</b></div><div class="request-top">${statusBadge(x.status)} <span class="closed-badge">Chiusa</span></div><p>${esc(x.message)}</p>${x.reply?`<div class="replybox"><b>Risposta Eurospin</b><p>${esc(x.reply)}</p></div>`:''}</article>`;
 }
 draw=function(){
  const list=all.filter(x=>mode==='open'?!x.replied_at:!!x.replied_at);
  document.getElementById('openTab').classList.toggle('active',mode==='open');document.getElementById('closedTab').classList.toggle('active',mode==='closed');
  const box=document.getElementById('inbox');if(!list.length){box.innerHTML='<div class="empty">Nessuna richiesta.</div>';return}
  const groups=new Map(),other=[];
  for(const x of list){const d=requestDate(x);if(!d){other.push(x);continue}const w=weekInfo(d);if(!groups.has(w.key))groups.set(w.key,{...w,items:[]});groups.get(w.key).items.push({x,d})}
  const ordered=[...groups.values()].sort((a,b)=>a.start-b.start);const now=new Date();
  box.innerHTML=ordered.map(g=>{g.items.sort((a,b)=>a.d-b.d);const current=now>=g.start&&now<=new Date(g.start.getTime()+7*86400000);return `<details class="request-week" ${mode==='open'||current?'open':''}><summary><div><b>${esc(g.label)}</b><small>${g.items.length} ${g.items.length===1?'richiesta':'richieste'}</small></div><span>⌄</span></summary><div class="request-week-body">${g.items.map(o=>card(o.x)).join('')}</div></details>`}).join('')+(other.length?`<details class="request-week" open><summary><div><b>Altre richieste</b><small>${other.length} ${other.length===1?'richiesta':'richieste'}</small></div><span>⌄</span></summary><div class="request-week-body">${other.map(card).join('')}</div></details>`:'');
  document.querySelectorAll('[data-normal]').forEach(b=>b.onclick=async()=>{const id=+b.dataset.normal,status=b.dataset.status,reply=status==='ACCETTATA'?'Richiesta accettata da Eurospin.':'Richiesta rifiutata da Eurospin.';if(!confirm(status==='ACCETTATA'?'Accettare questa richiesta?':'Rifiutare questa richiesta?'))return;b.disabled=true;try{await api('close_request',{method:'POST',body:{id,status,reply}});await load()}catch(e){alert(e.message);b.disabled=false}})
 };
 const style=document.createElement('style');style.textContent=`.request-week{background:#fff;border:1px solid #d9e4eb;border-radius:18px;overflow:hidden;margin-bottom:10px}.request-week>summary{list-style:none;cursor:pointer;padding:13px 14px;background:#eef5fa;color:#003d7c;display:flex;align-items:center;justify-content:space-between}.request-week>summary::-webkit-details-marker{display:none}.request-week>summary b,.request-week>summary small{display:block}.request-week>summary b{font-size:15px}.request-week>summary small{font-size:10px;color:#667c89;margin-top:2px}.request-week[open]>summary{border-bottom:1px solid #d9e4eb}.request-week-body{padding:9px}.request-week-body .request-item{margin-bottom:8px}.request-week-body .request-item:last-child{margin-bottom:0}`;document.head.appendChild(style);
 setTimeout(()=>{try{draw()}catch{}},0);
})();