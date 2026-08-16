(()=>{
 const oldFinish=finish;
 finish=async function(force){
   const issues=problems();
   if(issues.length&&!force)return;
   if(force&&!confirm('Confermi di applicare la turnazione anche con errori?'))return;

   const w=candidate.weeks[wi];
   const date=w.dates[di];
   const expected={};
   for(const n of Object.keys(w.schedule)) expected[n]=w.schedule[n][di];

   const key=`${req.employee}|${date}`;
   candidate.overrides=candidate.overrides||{};
   if(force)candidate.overrides[key]={approvedBy:'Eurospin',requestId:req.id,approvedAt:new Date().toISOString(),note:'Accettato da amministratore'};
   else if(candidate.overrides[key])delete candidate.overrides[key];
   candidate.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());

   const buttons=[...document.querySelectorAll('.final-actions button')];
   buttons.forEach(b=>b.disabled=true);
   try{
     await api('save_schedule',{method:'POST',body:{data:candidate}});

     // Verifica dal server che siano rimaste TUTTE le modifiche del giorno,
     // comprese quelle fatte agli altri colleghi per coprire/scambiare il turno.
     const check=await api('get_schedule');
     const saved=check?.data;
     const sw=saved?.weeks?.find(x=>x.dates?.includes(date));
     if(!sw)throw new Error('Salvataggio non verificato: settimana non trovata.');
     const savedDi=sw.dates.indexOf(date);
     const missing=[];
     for(const [n,s] of Object.entries(expected)){
       if((sw.schedule?.[n]||[])[savedDi]!==s)missing.push(n);
     }
     if(missing.length)throw new Error(`Non sono state salvate tutte le modifiche: ${missing.join(', ')}. Riprova senza chiudere la richiesta.`);

     await api('close_request',{method:'POST',body:{
       id:req.id,
       status:'ACCETTATA',
       reply:force?`${info.type} accettato comunque dall’amministratore: ${info.wanted}`:`${info.type} accettato e applicato: ${info.wanted}`
     }});
     location.href='inbox.html';
   }catch(e){
     alert(e.message||'Errore nel salvataggio dei turni.');
     buttons.forEach(b=>b.disabled=false);
   }
 };
})();