(function(){
  async function syncCloudMovements(){
    if(!window.CLOUD||!window.CLOUD.url||!window.CLOUD.key||!window.CLOUD.table)return;
    try{
      const url=window.CLOUD.url+'/rest/v1/'+encodeURIComponent(window.CLOUD.table)+'?select=Id,Created_at,Importo,Esercente,Categoria,Tipo&order=Created_at.desc';
      const r=await fetch(url,{headers:{apikey:window.CLOUD.key,Authorization:'Bearer '+window.CLOUD.key}});
      if(!r.ok)throw new Error('HTTP '+r.status);
      const rows=await r.json();
      let changed=false;
      for(const row of rows){
        const cloudId=String(row.Id);
        if(state.movements.some(m=>String(m.cloudId||'')===cloudId))continue;
        const merchant=row.Esercente||'Pagamento Wallet';
        const rawDate=row.Created_at?new Date(row.Created_at):new Date();
        const date=Number.isNaN(rawDate.getTime())?today():`${rawDate.getFullYear()}-${String(rawDate.getMonth()+1).padStart(2,'0')}-${String(rawDate.getDate()).padStart(2,'0')}`;
        const amount=Number(row.Importo||0);
        if(!amount||amount<=0)continue;
        const dbCat=(row.Categoria||'').trim();
        const category=dbCat&&dbCat.toLowerCase()!=='altro'?dbCat:guessCategory(merchant);
        state.movements.push({id:Date.now()+Math.floor(Math.random()*100000),cloudId,type:row.Tipo||'expense',amount,category,date,description:merchant,source:'supabase'});
        changed=true;
      }
      if(changed){save(false);render();toast('Spese Wallet sincronizzate');}
    }catch(e){console.warn('Sincronizzazione cloud non riuscita',e);}
  }
  window.syncCloudMovements=syncCloudMovements;
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(syncCloudMovements,350));
  else setTimeout(syncCloudMovements,350);
  window.addEventListener('focus',syncCloudMovements);
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)syncCloudMovements();});
})();
