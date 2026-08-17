(()=>{
 const app=document.getElementById('app');
 const style=document.createElement('style');style.textContent=`.future-week-wrap{min-height:100vh;background:#f4f7fa}.future-week-head{background:#0067b1;color:#fff;border-bottom:5px solid #ffd100;padding:14px}.future-week-head a{color:#fff;font-weight:900;text-decoration:none}.future-week-main{max-width:620px;margin:auto;padding:18px 12px}.future-card{background:#fff;border:1px solid #dbe5ec;border-radius:22px;padding:20px;box-shadow:0 8px 28px rgba(0,54,100,.07)}.future-icon{width:58px;height:58px;border-radius:18px;background:#fff3b6;display:grid;place-items:center;font-size:28px;margin-bottom:14px}.future-card h2{margin:0 0 8px;color:#003d7c}.future-card p{color:#607583;line-height:1.45}.future-request{background:#eef5fa;border-radius:14px;padding:12px;margin:14px 0}.future-request b,.future-request span{display:block}.future-request b{color:#003d7c}.future-request span{margin-top:4px;font-size:13px}.future-actions{display:grid;gap:9px;margin-top:16px}.future-actions a{padding:13px;border-radius:13px;text-align:center;text-decoration:none;font-weight:950}.future-primary{background:#0067b1;color:#fff}.future-secondary{background:#ffd100;color:#003d7c}.future-back{background:#fff;color:#003d7c;border:1px solid #c9d8e3}.review-loading{min-height:55vh;display:grid;place-items:center;color:#597080;font-weight:900}`;document.head.appendChild(style);
 function qp(name){return new URLSearchParams(location.search).get(name)}
 function script(src){return new Promise((resolve,reject)=>{const s=document.createElement('script');s.src=src;s.onload=resolve;s.onerror=reject;document.body.appendChild(s)})}
 async function loadEditor(){for(const src of ['review-change.js?v=33','review-change-fix.js?v=33','review-persist-fix.js?v=33','review-error-days.js?v=33','review-advice-fix.js?v=33'])await script(src)}
 async function boot(){
  app.innerHTML='<div class="review-loading">Controllo settimana…</div>';
  try{
   const id=Number(qp('id')||qp('request')||qp('requestId'));
   if(!id){app.innerHTML='<div class="error" style="margin:20px">Richiesta non trovata.</div>';return}
   const [rr,data]=await Promise.all([api('list_requests'),loadSchedule()]);
   const r=(rr.requests||[]).find(x=>Number(x.id)===id);
   if(!r){app.innerHTML='<div class="error" style="margin:20px">Richiesta non trovata.</div>';return}
   const m=String(r.message||'');
   const dateLabel=(m.match(/Giorno:\s*([^\n]+)/)||[])[1]?.trim();
   if(!dateLabel){await loadEditor();return}
   const exists=(data.weeks||[]).some(w=>(w.dates||[]).some(d=>fmtDate(d)===dateLabel));
   if(exists){app.innerHTML='';await loadEditor();return}
   const wanted=(m.match(/Turno richiesto:\s*([^\n]+)/)||[])[1]?.trim()||(/RICHIESTA RIPOSO/.test(m)?'RIPOSO':/RICHIESTA FERIE/.test(m)?'FERIE':/RICHIESTA PERMESSO/.test(m)?'PERMESSO':'turno da concordare');
   app.innerHTML=`<div class="future-week-wrap"><header class="future-week-head"><a href="inbox.html">‹ Richieste</a></header><main class="future-week-main"><section class="future-card"><div class="future-icon">📅</div><h2>Settimana ancora da creare</h2><p>Questa richiesta riguarda una settimana che non è stata ancora generata. Non c'è ancora una turnazione da modificare.</p><div class="future-request"><b>${esc(r.employee)} · ${esc(dateLabel)}</b><span>Richiesta: ${esc(wanted)}</span></div><p>Quando creerai la settimana corretta, questa richiesta comparirà automaticamente in <b>Nuovi Turni</b> e potrai applicarla alla bozza.</p><div class="future-actions"><a class="future-primary" href="new-turns.html">Vai a Nuovi Turni</a><a class="future-secondary" href="inbox.html">Torna alle richieste</a><a class="future-back" href="index.html">Home</a></div></section></main></div>`;
  }catch(e){app.innerHTML=`<div class="error" style="margin:20px">${esc(e.message||'Errore caricamento richiesta')}</div>`}
 }
 boot();
})();