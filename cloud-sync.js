(function(){
  const pct=n=>Math.max(0,Math.min(100,Number(n??100)));
  const cloudHeaders=()=>({apikey:window.CLOUD.key,Authorization:'Bearer '+window.CLOUD.key,'Content-Type':'application/json'});
  const cloudBase=()=>window.CLOUD.url+'/rest/v1/'+encodeURIComponent(window.CLOUD.table);

  function ensureShareUI(){
    const home=document.getElementById('home');
    if(!home||document.getElementById('shareSummary'))return;
    const box=document.createElement('div');
    box.id='shareSummary';
    box.className='statsGrid';
    box.style.marginBottom='14px';
    box.innerHTML='<div class="metric"><span class="label">LE MIE SPESE · CICLO</span><b id="myExpenseTotal">€0,00</b><small class="label" style="display:block;margin-top:5px">Dopo le divisioni con Elisa</small></div><div class="metric"><span class="label">QUOTA ELISA · CICLO</span><b id="elisaExpenseTotal">€0,00</b><small class="label" style="display:block;margin-top:5px">Parte delle spese a carico di Elisa</small></div>';
    const grid=home.querySelector('.grid');
    home.insertBefore(box,grid);
    const style=document.createElement('style');
    style.textContent='.shareBox{grid-column:1/-1;border:1px solid #2b3342;border-radius:16px;padding:14px;background:#11151d}.sharePills{display:grid;grid-template-columns:repeat(5,1fr);gap:7px;margin-top:10px}.sharePill{border:1px solid #313a4a;background:#171c26;color:#d9e0ea;border-radius:12px;padding:10px 4px;font-weight:800}.sharePill.on{border-color:var(--green);background:rgba(100,230,149,.12);color:var(--green)}.sharePreview{display:flex;justify-content:space-between;gap:12px;margin-top:11px;font-size:13px}.splitBadge{color:var(--green);font-weight:750}';
    document.head.appendChild(style);
  }

  function renderShareSummary(){
    ensureShareUI();
    if(!document.getElementById('myExpenseTotal'))return;
    const ms=state.movements.filter(m=>m.type==='expense'&&inCycle(m));
    let mine=0,elisa=0;
    for(const m of ms){const p=pct(m.mySharePct);mine+=Number(m.amount||0)*p/100;elisa+=Number(m.amount||0)*(100-p)/100;}
    document.getElementById('myExpenseTotal').textContent=money(mine);
    document.getElementById('elisaExpenseTotal').textContent=money(elisa);
  }

  const baseRender=render;
  render=function(){baseRender();renderShareSummary();};

  movementHTML=function(m,del=false){
    let c=categoryInfo(m.category),p=pct(m.mySharePct),split=p<100?` · <span class="splitBadge">🤝 Tu ${p}% · Elisa ${100-p}%</span>`:'';
    return `<div class="movement" onclick="editMovement(${m.id})"><div class="icon">${m.category==='Stipendio'?'💶':c[1]}</div><div><div class="mname">${esc(m.description||m.category)}</div><div class="mmeta">${esc(m.category)} · ${new Date(m.date+'T12:00').toLocaleDateString('it-IT')}${split}</div></div><div class="amountText ${m.type==='income'?'income':'expense'}">${m.type==='income'?'+':'-'}${money(m.amount)}</div>${del?`<button class="deleteMini" onclick="event.stopPropagation();deleteMovement(${m.id})">Elimina</button>`:''}</div>`;
  };

  window.setSharePct=function(v){
    const el=document.getElementById('eShare');if(!el)return;el.value=v;
    document.querySelectorAll('.sharePill').forEach(b=>b.classList.toggle('on',Number(b.dataset.pct)===Number(v)));
    updateSharePreview();
  };
  window.updateSharePreview=function(){
    const amount=Number(document.getElementById('eAmount')?.value||0),p=pct(document.getElementById('eShare')?.value);
    const a=document.getElementById('shareMine'),b=document.getElementById('shareElisa');
    if(a)a.textContent=money(amount*p/100);if(b)b.textContent=money(amount*(100-p)/100);
  };

  editMovement=function(id){
    let m=state.movements.find(x=>x.id===id);if(!m)return;let p=pct(m.mySharePct);
    $('modalContent').innerHTML=`<div class="formGrid"><div class="field"><label>Tipo</label><select id="eType"><option value="expense" ${m.type==='expense'?'selected':''}>Spesa</option><option value="income" ${m.type==='income'?'selected':''}>Entrata</option></select></div><div class="field"><label>Importo</label><input id="eAmount" type="number" step="0.01" value="${m.amount}" oninput="updateSharePreview()"></div><div class="field"><label>Categoria</label><select id="eCat">${cats.map(c=>`<option ${m.category===c[0]?'selected':''}>${c[0]}</option>`).join('')}<option ${m.category==='Stipendio'?'selected':''}>Stipendio</option></select></div><div class="field"><label>Data</label><input id="eDate" type="date" value="${m.date}"></div><div class="field full"><label>Descrizione</label><input id="eDesc" value="${esc(m.description||'')}"></div>${m.type==='expense'?`<div class="shareBox"><b>🤝 Dividi con Elisa</b><div class="label" style="margin-top:4px">Scegli la percentuale della spesa che resta a tuo carico</div><input id="eShare" type="hidden" value="${p}"><div class="sharePills">${[100,75,50,25,0].map(x=>`<button type="button" data-pct="${x}" class="sharePill ${p===x?'on':''}" onclick="setSharePct(${x})">${x}%</button>`).join('')}</div><div class="sharePreview"><span>Tu: <b id="shareMine">${money(Number(m.amount)*p/100)}</b></span><span>Elisa: <b id="shareElisa">${money(Number(m.amount)*(100-p)/100)}</b></span></div></div>`:''}</div><div class="actions"><button class="secondary danger" onclick="deleteMovement(${m.id});closeModal()">Elimina</button><button class="primary" onclick="applyEdit(${m.id})">Salva modifiche</button></div>`;
    $('modalBack').classList.add('show');
  };

  async function patchCloud(m){
    if(!m.cloudId||!window.CLOUD)return;
    const body={Importo:Number(m.amount),Esercente:m.description||'',Categoria:m.category,Tipo:m.type,Quota_mia:pct(m.mySharePct),Created_at:m.date+'T12:00:00+02:00'};
    const r=await fetch(cloudBase()+'?Id=eq.'+encodeURIComponent(m.cloudId),{method:'PATCH',headers:cloudHeaders(),body:JSON.stringify(body)});
    if(!r.ok)throw new Error('HTTP '+r.status);
  }

  applyEdit=async function(id){
    let m=state.movements.find(x=>x.id===id),a=parseFloat($('eAmount').value);if(!a||a<=0){toast('Importo non valido');return;}
    m.type=$('eType').value;m.amount=a;m.category=$('eCat').value;m.date=$('eDate').value;m.description=$('eDesc').value.trim();m.mySharePct=m.type==='expense'?pct(document.getElementById('eShare')?.value):100;
    save();closeModal();toast('Modifiche salvate');
    try{await patchCloud(m);}catch(e){toast('Salvato sul telefono, sincronizzazione non riuscita');}
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
      const url=cloudBase()+'?select=Id,Created_at,Importo,Esercente,Categoria,Tipo,Quota_mia&order=Created_at.desc';
      const r=await fetch(url,{headers:cloudHeaders()});if(!r.ok)throw new Error('HTTP '+r.status);
      const rows=await r.json(),live=new Set();let changed=false;
      for(const row of rows){
        const cloudId=String(row.Id),amount=Number(row.Importo||0);live.add(cloudId);if(!amount||amount<=0)continue;
        const merchant=row.Esercente||'Pagamento Wallet',rawDate=row.Created_at?new Date(row.Created_at):new Date();
        const date=Number.isNaN(rawDate.getTime())?today():`${rawDate.getFullYear()}-${String(rawDate.getMonth()+1).padStart(2,'0')}-${String(rawDate.getDate()).padStart(2,'0')}`;
        const dbCat=(row.Categoria||'').trim(),category=dbCat&&dbCat.toLowerCase()!=='altro'?dbCat:guessCategory(merchant),share=pct(row.Quota_mia);
        let m=state.movements.find(x=>String(x.cloudId||'')===cloudId);
        if(!m){state.movements.push({id:Date.now()+Math.floor(Math.random()*100000),cloudId,type:row.Tipo||'expense',amount,category,date,description:merchant,source:'supabase',mySharePct:share});changed=true;}
        else{
          const next={type:row.Tipo||'expense',amount,category,date,description:merchant,mySharePct:share};
          if(Object.keys(next).some(k=>String(m[k]??'')!==String(next[k]??''))){Object.assign(m,next);changed=true;}
        }
      }
      const before=state.movements.length;
      state.movements=state.movements.filter(m=>m.source!=='supabase'||!m.cloudId||live.has(String(m.cloudId)));
      if(state.movements.length!==before)changed=true;
      if(changed){save(false);render();toast('Spese sincronizzate');}else renderShareSummary();
    }catch(e){console.warn('Sincronizzazione cloud non riuscita',e);}
  }

  window.syncCloudMovements=syncCloudMovements;
  ensureShareUI();renderShareSummary();
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(syncCloudMovements,350));else setTimeout(syncCloudMovements,350);
  window.addEventListener('focus',syncCloudMovements);
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)syncCloudMovements();});
})();
