(()=>{
 const protectedAbsence=arr=>(arr||[]).some(s=>['FERIE','MALATTIA','MATERNITÀ','PERMESSO'].includes(s));
 const desired=n=>RESP.has(n)?42:(TARGETS[n]||40);
 // Obiettivi ore mostrati nell'app: responsabili 42h, full time 40h, Giada 30h, Marco 16h.
 target=function(n){return desired(n)};

 const oldValidate=validateWeek;
 validateWeek=function(w){
  let issues=oldValidate(w);
  // Le ore sopra il target NON sono un errore. Rimuove i vecchi errori di ore esatte/straordinario.
  issues=issues.filter(x=>{
   const s=String(x||'');
   if(/^Marco: .*h invece di 16h/.test(s))return false;
   if(/^Giada: .*h invece di 30h/.test(s))return false;
   if(/: .*h invece delle 40h contrattuali/.test(s))return false;
   return true;
  });
  if(!w?.schedule)return [...new Set(issues)];
  for(const n of Object.keys(w.schedule)){
   const arr=w.schedule[n]||[];
   if(protectedAbsence(arr))continue;
   const h=weekHours(w,n),t=desired(n);
   // Per i responsabili 42h è l'obiettivo del generatore, non un errore bloccante:
   // domenica/riposo e le altre regole possono rendere necessario stare sotto o sopra.
   if(RESP.has(n))continue;
   if(h<t)issues.push(`${n}: ${h}h, obiettivo ${t}h`);
  }
  return [...new Set(issues)];
 };
})();