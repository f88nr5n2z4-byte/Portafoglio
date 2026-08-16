const u=requireUser(true),app=document.getElementById('app');
if(u){
  app.innerHTML=`<div class="app-shell"><div class="brandbar"></div><header class="topbar"><div class="toprow"><a class="back" href="index.html">‹ Turni</a><div class="brand-mini"><div class="mini-mark">E</div><div><strong>Richieste ricevute</strong><span>Solo account Eurospin</span></div></div><button class="logout" onclick="logout()">Esci</button></div></header><main class="main"><section class="hero inboxhero"><div class="eyebrow">Messaggi dipendenti</div><h2>Tutte le richieste</h2><p>Ordinate dalla più recente.</p></section><div class="section-title"><h3>Richieste</h3><span id="count">Caricamento…</span></div><div id="inbox" class="request-list"><div class="empty">Caricamento…</div></div></main></div>`;
  async function load(){
    try{
      const r=await api('list_requests');const list=r.requests||[];
      document.getElementById('count').textContent=`${list.length} totali`;
      document.getElementById('inbox').innerHTML=list.length?list.map(x=>`<article class="request-item"><div class="request-meta">${esc(formatDateTime(x.created_at))} · <b>${esc(x.employee)}</b></div><p>${esc(x.message)}</p></article>`).join(''):'<div class="empty">Nessuna richiesta ricevuta.</div>';
    }catch(e){document.getElementById('inbox').innerHTML=`<div class="error">${esc(e.message)}</div>`}
  }
  load();
}
