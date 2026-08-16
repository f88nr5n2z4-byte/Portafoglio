(function(){
  const cloudHeaders=()=>({apikey:window.CLOUD.key,Authorization:'Bearer '+window.CLOUD.key,'Content-Type':'application/json'});
  const cloudBase=()=>window.CLOUD.url+'/rest/v1/'+encodeURIComponent(window.CLOUD.table);

  function ensureSettlementUI(){
    const home=document.getElementById('home');
    if(!home||document.getElementById('settlementSummary'))return;
    const box=document.createElement('div');
    box.id='settlementSummary';
    box.className='card';
    box.style.marginBottom='14px';
    box.innerHTML='<div class="row"><div><div class="label">DA CONTEGGIARE</div><div class="big" id="unsettledTotal" style="font-size:32px;margin:5px 0">€0,00</div><small class="label" id="unsettledCount">Nessuna spesa aperta</small></div><button class="primary" id="settleAllBtn" onclick="settleAllExpenses()">✓ Segna saldate</button></div><div class="label" style="margin-top:10px">Usa questo totale quando devi fare i conti. Quando avete chiuso i conti, premi “Segna saldate”: quelle spese non verranno più sommate qui.</div>';
    const grid=home.querySelector('.grid');
    home.insertBefore(box,grid);
    const style=document.createElement('style');
    style.textContent='.settledBadge{color:#93a0b4;font-weight:750}.openBadge{color:var(--green);font-weight:800}.settleBox{grid-column:1/-1;border:1px solid #2b3342;border-radius:16px;padding:14px;background:#11151d}.settleChoices{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px}.settleChoice{border:1px solid #313a4a;background:#171c26;color:#d9e0ea;border-radius:12px;padding:11px;font-weight:800}.settleChoice.on{border-color:var(--green);background:rgba(100,230,149,.12);color:var(--green)}@media(max-width:760px){#settlementSummary .row{align-items:center;gap:12px}#settleAllBtn{padding:11px 12px;font-size:13px}}';
    document.head.appendChild(style);
  }

  function openExpenses(){return state.movements.filter(m=>m.type==='expense'&&!m.settled);}
  function renderSettlementSummary(){
    ensureSettlementUI();
    const ms=openExpenses(),total=ms.reduce((a,m)=>a+Number(m.amount||0),0);
    const t=document.getElementById('unsettledTotal'),c=document.getElementById('unsettledCount'),b=document.getElementById('settleAllBtn');
    if(t)t.textContent=money(total);
    if(c)c.textContent=ms.length?`${ms.length} ${ms.length===1?'spesa aperta':'spese aperte'}`:'Nessuna spesa aperta';
    if(b)b.disabled=!ms.length;
  }

  const baseRender=render;
  render=function(){baseRender();renderSettlementSummary();};

  movementHTML=function(m,del=false){
    let c=categoryInfo(m.category),status=m.type==='expense'?(m.settled?' · <span class="settledBadge">✓ Saldata</span>':' · <span class="openBadge">Da conteggiare</span>'):'';
    return `<div class="movement" onclick="editMovement(${m.id})"><div class="icon">${m.category==='Stipendio'?'💶':c[1]}</div><div><div class="mname">${esc(m.description||m.category)}</div><div class="mmeta">${esc(m.category)} · ${new Date(m.date+'T12:00').toLocaleDateString('it-IT')}${status}</div></div><div class="amountText ${m.type==='income'?'income':'expense'}">${m.type==='income'?'+':'-'}${money(m.amount)}</div>${del?`<button class="deleteMini" onclick="event.stopPropagation();deleteMovement(${m.id})">Elimina</button>`:''}</div>`;
  };

  window.setSettledChoice=function(v){
    const el=document.getElementById('eSettled');if(!el)return;el.value=v?'1':'0';
    document.querySelectorAll('.settleChoice').forEach(b=>b.classList.toggle('on',b.dataset.value===(v?'1':'0')));
  };

  editMovement=function(id){
    let m=state.movements.find(x=>x.id===id);if(!m)return;const settled=!!m.settled;
    $('modalContent').innerHTML=`<div class="formGrid"><div class="field"><label>Tipo</label><select id="eType"><option value="expense" ${m.type==='expense'?'selected':''}>Spesa</option><option value="income" ${m.type==='income'?'selected':''}>Entrata</option></select></div><div class="field"><label>Importo</label><input id="eAmount" type="number" step="0.01" value="${m.amount}"></div><div class="field"><label>Categoria</label><select id="eCat">${cats.map(c=>`<option ${m.category===c[0]?'selected':''}>${c[0]}</option>`).join('')}<option ${m.category==='Stipendio'?'selected':''}>Stipendio</option></select></div><div class="field"><label>Data</label><input id="eDate" type="date" value="${m.date}"></div><div class="field full"><label>Descrizione</label><input id="eDesc" value="${esc(m.description||'')}"></div>${m.type==='expense'?`<div class="settleBox"><b>Stato della spesa</b><div class="label" style="margin-top:4px">“Saldata” significa che questa spesa è già stata conteggiata e non va inclusa nei prossimi conti.</div><input id="eSettled" type="hidden" value="${settled?'1':'0'}"><div class="settleChoices"><button type="button" data-value="0" class="settleChoice ${!settled?'on':''}" onclick="setSettledChoice(false)">Da conteggiare</button><button type="button" data-value="1" class="settleChoice ${settled?'on':''}" onclick="setSettledChoice(true)">✓ Saldata</button></div></div>`:''}</div><div class="actions"><button class="secondary danger" onclick="deleteMovement(${m.id});closeModal()">Elimina</button><button class="primary" onclick="applyEdit(${m.id})">Salva modifiche</button></div>`;
    $('modalBack').classList.add('show');
  };

  async function patchCloud(m){
    if(!m.cloudId||!window.CLOUD)return;
    const body={Importo:Number(m.amount),Esercente:m.description||'',Categoria:m.category,Tipo:m.type,Saldata:!!m.settled,Saldata_il:m.settled?new Date().toISOString():null,Created_at:m.date+'T12:00:00+02:00'};
    const r=await fetch(cloudBase()+'?Id=eq.'+encodeURIComponent(m.cloudId),{method:'PATCH',headers:cloudHeaders(),body:JSON.stringify(body)});
    if(!r.ok)throw new Error('HTTP '+r.status);
  }

  applyEdit=async function(id){
    let m=state.movements.find(x=>x.id===id),a=parseFloat($('eAmount').value);if(!a||a<=0){toast('Importo non valido');return;}
    m.type=$('eType').value;m.amount=a;m.category=$('eCat').value;m.date=$('eDate').value;m.description=$('eDesc').value.trim();m.settled=m.type==='expense'?(document.getElementById('eSettled')?.value==='1'):false;
    save();closeModal();toast('Modifiche salvate');
    try{await patchCloud(m);}catch(e){toast('Salvato sul telefono, sincronizzazione non riuscita');}
  };

  window.settleAllExpenses=async function(){
    const ms=openExpenses();if(!ms.length)return;
    if(!confirm(`Segnare come saldate ${ms.length} spese per un totale di ${money(ms.reduce((a,m)=>a+Number(m.amount||0),0))}?`))return;
    const now=new Date().toISOString();
    for(const m of ms){m.settled=true;}
    save();toast('Spese segnate come saldate');
    const cloudIds=ms.filter(m=>m.cloudId).map(m=>m.cloudId);
    if(cloudIds.length&&window.CLOUD){
      try{
        const r=await fetch(cloudBase()+'?Id=in.('+cloudIds.map(x=>encodeURIComponent(x)).join(',')+')',{method:'PATCH',headers:cloudHeaders(),body:JSON.stringify({Saldata:true,Saldata_il:now})});
        if(!r.ok)throw new Error('HTTP '+r.status);
      }catch(e){toast('Salvate sul telefono, sincronizzazione non riuscita');}
    }
  };

  deleteMovement=async function(id){
    const m=state.movements.find(x=>x.id===id);if(!m)return;
    if(m.autoSalaryKey&&!confirm('Questo è un accredito automatico dello stipendio. Eliminarlo?'))return;
    if(m.cloudId&&window.CLOUD){
      try{
        const r=await fetch(cloudBase()+'?Id=eq.'+encodeURIComponent(m.cloudId),{method:'DELETE',headers:cloudHeaders()});
        if(!r.ok)throw new Error('HTTP '+r.status);
      }catch(e){toast('Non riesco a cancellarlo dal database');return;}
    }
    state.movements=state.movements.filter(x=>x.id!==id);save();toast('Movimento eliminato');
  };

  async function syncCloudMovements(){
    if(!window.CLOUD||!window.CLOUD.url||!window.CLOUD.key||!window.CLOUD.table)return;
    try{
      const url=cloudBase()+'?select=Id,Created_at,Importo,Esercente,Categoria,Tipo,Saldata,Saldata_il&order=Created_at.desc';
      const r=await fetch(url,{headers:cloudHeaders()});if(!r.ok)throw new Error('HTTP '+r.status);
      const rows=await r.json(),live=new Set();let changed=false;
      for(const row of rows){
        const cloudId=String(row.Id),amount=Number(row.Importo||0);live.add(cloudId);if(!amount||amount<=0)continue;
        const merchant=row.Esercente||'Pagamento Wallet',rawDate=row.Created_at?new Date(row.Created_at):new Date();
        const date=Number.isNaN(rawDate.getTime())?today():`${rawDate.getFullYear()}-${String(rawDate.getMonth()+1).padStart(2,'0')}-${String(rawDate.getDate()).padStart(2,'0')}`;
        const dbCat=(row.Categoria||'').trim(),category=dbCat&&dbCat.toLowerCase()!=='altro'?dbCat:guessCategory(merchant);
        let m=state.movements.find(x=>String(x.cloudId||'')===cloudId);
        const next={type:row.Tipo||'expense',amount,category,date,description:merchant,settled:!!row.Saldata};
        if(!m){state.movements.push({id:Date.now()+Math.floor(Math.random()*100000),cloudId,source:'supabase',...next});changed=true;}
        else if(Object.keys(next).some(k=>String(m[k]??'')!==String(next[k]??''))){Object.assign(m,next);changed=true;}
      }
      const before=state.movements.length;
      state.movements=state.movements.filter(m=>m.source!=='supabase'||!m.cloudId||live.has(String(m.cloudId)));
      if(state.movements.length!==before)changed=true;
      if(changed){save(false);render();toast('Spese sincronizzate');}else renderSettlementSummary();
    }catch(e){console.warn('Sincronizzazione cloud non riuscita',e);}
  }

  window.syncCloudMovements=syncCloudMovements;
  ensureSettlementUI();renderSettlementSummary();
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(syncCloudMovements,350));else setTimeout(syncCloudMovements,350);
  window.addEventListener('focus',syncCloudMovements);
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)syncCloudMovements();});
})();
