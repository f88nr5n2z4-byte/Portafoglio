(()=>{
'use strict';
let effectiveV128='';
prepare=function(){
 candidate=clone(data);const w=candidate.weeks[wi],old=clone(w),date=w.dates[di],requested=String(info.wanted).toUpperCase();changes=[];advice=[];effectiveV128=info.wanted;
 const otherRest=(w.schedule[req.employee]||[]).some((s,i)=>i!==di&&String(s).toUpperCase()==='RIPOSO');
 if(requested==='RIPOSO'&&!C.isSunday(date)&&otherRest){effectiveV128='PERMESSO';advice.push('La persona ha già il suo RIPOSO settimanale: questo nuovo giorno viene segnato come PERMESSO. Il riposo già presente non viene spostato.');}
 if(requested==='RIPOSO'&&C.isSunday(date)&&works(w.schedule[req.employee][di])){
  const g=group(req.employee),other=g?.filter(n=>n!==req.employee&&!works(w.schedule[n][di]))?.sort((a,b)=>C.weekHours(w,a)-C.weekHours(w,b))[0];
  if(other){effectiveV128='RIPOSO';w.schedule[req.employee][di]='RIPOSO';w.schedule[other][di]='08:00-13:00';swapRotation(req.employee,other);advice.push(`Scambiare la domenica con ${other}. Il ciclo futuro continuerà con ${req.employee} e ${other} scambiati.`)}
  else advice.push('Non c’è un collega della stessa mansione disponibile per lo scambio domenicale.');
  record(old,w,di);return;
 }
 if(OFF.has(String(effectiveV128).toUpperCase())){
  w.schedule[req.employee][di]=String(effectiveV128).toUpperCase();
  if(!valid(w,di)){const sol=solveMissing(w,di,req.employee);if(sol){for(const[n,s]of Object.entries(sol.a))w.schedule[n][di]=s;advice.push('Per coprire la giornata ho modificato soltanto i turni di questo giorno. Gli altri giorni della settimana restano invariati.')}else advice.push('Il giorno richiesto è stato segnato. Se serve, puoi sistemare manualmente soltanto questa giornata.')}
 }else{
  w.schedule[req.employee][di]=effectiveV128;let found=null;
  for(const n of ALL){if(n===req.employee||!works(old.schedule[n][di]))continue;const sim=clone(old);sim.schedule[req.employee][di]=effectiveV128;sim.schedule[n][di]=info.current;if(valid(sim,di)){found=n;w.schedule[n][di]=info.current;break}}
  if(found)advice.push(`Scambiare turno con ${found}.`);else advice.push('Il turno richiesto è stato inserito. Eventuali aggiustamenti riguardano soltanto questa giornata.');
 }
 record(old,w,di);
};
render=function(){
 const w=candidate.weeks[wi],date=w.dates[di],changed=new Set(changes.map(x=>x.n));
 app.innerHTML=`<div class="rv126 rv128"><header><a href="inbox.html">‹ Richieste</a><strong>Visualizza Turnazione</strong><span></span></header><main><section class="summary"><small>${esc(req.employee)} · ${esc(fmtDate(date))}</small><h2>${esc(info.current)} → ${esc(effectiveV128)}</h2>${effectiveV128!==info.wanted?`<p>Richiesta originale: ${esc(info.wanted)} · gestita come <b>${esc(effectiveV128)}</b></p>`:''}</section><section class="day ${changes.length?'changed-day':''}"><div class="daytitle"><div><b>${esc(fmtDate(date))}</b><small>${changes.length?'Giorno interessato dalle modifiche':'Giorno della richiesta'}</small></div></div><div class="grid"><div class="gh">Dipendente</div><div class="gh">Mattina</div><div class="gh">Pomeriggio</div>${ALL.map(n=>{const s=w.schedule[n][di]||'—',p=parts(s),cl=n===req.employee?'requested':changed.has(n)?'changed':'';return `<div class="person ${cl}">${esc(n)}${changed.has(n)?'<small>Modificato</small>':''}</div><button class="${cl}" data-edit="${esc(n)}">${esc(p.m)}</button><button class="${cl}" data-edit="${esc(n)}">${esc(p.p)}</button>`}).join('')}</div></section><section class="advice"><h3>Consiglio</h3>${advice.map(x=>`<p>${esc(x)}</p>`).join('')}${changes.length?`<div class="changedlist"><b>Persone modificate in questa giornata:</b>${changes.map(x=>`<div><strong>${esc(x.n)}</strong> ${esc(x.from)} → ${esc(x.to)}</div>`).join('')}</div>`:''}</section><div class="actions"><button class="accept" id="accept">Conferma e applica</button><button class="reject" id="reject">Rifiuta richiesta</button></div></main></div>`;
 document.querySelectorAll('[data-edit]').forEach(b=>b.onclick=()=>edit(b.dataset.edit));document.getElementById('accept').onclick=finishV128;document.getElementById('reject').onclick=rejectReq;
};
async function finishV128(){candidate.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());await api('save_schedule',{method:'POST',body:{data:candidate}});if(candidate.rotationMap)localStorage.setItem('tm_rotation_v125',JSON.stringify(candidate.rotationMap));await api('close_request',{method:'POST',body:{id:req.id,status:'ACCETTATA',reply:`Richiesta accettata e turnazione aggiornata: ${effectiveV128}`}});location.href='inbox.html'}
const css=document.createElement('style');css.textContent='.rv128 .daytitle>span,.rv128 .warning,.rv128 .live-status{display:none!important}.rv128 .summary p{color:#607583}.rv128 .advice>p{font-weight:900;color:#425f70}';document.head.appendChild(css);
})();