(()=>{
  const NO_PUSH_URL='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-write-no-push';
  const originalApi=api;
  api=async function(action,{method='GET',body=null}={}){
    if(action!=='create_request'&&action!=='save_schedule')return originalApi(action,{method,body});
    const u=getSession();
    if(!u)throw new Error('Sessione scaduta');
    let res;
    try{
      res=await fetch(`${NO_PUSH_URL}?action=${encodeURIComponent(action)}`,{
        method,
        headers:{'Content-Type':'application/json','x-user':u.key,'x-pass':u.password},
        body:body?JSON.stringify(body):null,
        cache:'no-store'
      });
    }catch(e){
      throw new Error('Connessione non riuscita. Riprova.');
    }
    const data=await res.json().catch(()=>({error:'Risposta non valida'}));
    if(!res.ok)throw new Error(data.error||'Errore di connessione');
    return data;
  };
})();