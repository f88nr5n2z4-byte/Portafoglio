(()=>{
 const CASH_FALLBACK=new Set(['Giuliano','Daniele','Manuel','Emanuele']);
 const oldValidate=validateWeek;
 validateWeek=function(w){
  let issues=oldValidate(w);
  if(!w?.dates||!w?.schedule)return issues;

  // Alle 13:30 la cassiera dedicata è preferibile, ma non obbligatoria:
  // può coprire una persona di sala abilitata. Paolo e Marco NON possono fare cassa.
  issues=issues.filter(x=>!String(x||'').includes('manca cassa dedicata alle 13:30'));

  w.dates.forEach((iso,i)=>{
   const day=new Date(iso+'T12:00:00').getDay();
   if(day===0)return;
   const active=Object.entries(w.schedule).filter(([,a])=>a[i]&&!ABSENCES.has(a[i]));
   const dedicated=active.some(([n,a])=>CASH.has(n)&&present(a[i],'13:30'));
   if(dedicated)return;
   const fallback=active.some(([n,a])=>CASH_FALLBACK.has(n)&&present(a[i],'13:30'));
   if(!fallback)issues.push(`${fmtDate(iso)}: alle 13:30 manca sia cassa dedicata sia sala abilitata alla cassa (Paolo e Marco esclusi)`);
  });

  return [...new Set(issues)];
 };
})();