(()=>{
 const PROTECTED_RESP=new Set(['FERIE','MALATTIA','MATERNITÀ','PERMESSO']);
 function missingResponsibleCount(w,di){
  return [...RESP].filter(n=>{
   const s=w?.schedule?.[n]?.[di]||'—';
   return PROTECTED_RESP.has(s)||s==='—';
  }).length;
 }
 function isRespNormalShift(s){return s==='06:30-13:30'||s==='13:30-20:30'}
 function isRespSplit(s){return spans(s).length>1}
 const oldValidate=validateWeek;
 validateWeek=function(w){
  const issues=oldValidate(w);
  if(!w?.dates||!w?.schedule)return issues;
  w.dates.forEach((iso,di)=>{
   const day=new Date(iso+'T12:00:00').getDay();
   if(day===0)return;
   const missing=missingResponsibleCount(w,di);
   for(const n of RESP){
    const s=w.schedule[n]?.[di]||'—';
    if(ABSENCES.has(s))continue;
    if(isRespSplit(s)){
     if(missing<2)issues.push(`${fmtDate(iso)}: ${n} fa spezzato da responsabile, ammesso solo se mancano due responsabili nello stesso giorno`);
     continue;
    }
    if(!isRespNormalShift(s))issues.push(`${fmtDate(iso)}: ${n} responsabile deve fare 06:30-13:30 o 13:30-20:30`);
   }
  });
  return [...new Set(issues)];
 };

 if(typeof candidates==='function'){
  const oldCandidates=candidates;
  candidates=function(n,cur){
   if(RESP.has(n))return [cur,'06:30-13:30','13:30-20:30','08:00-13:00','RIPOSO'];
   return oldCandidates(n,cur);
  };
 }

 if(typeof buildBase==='function'){
  const oldBuildBase=buildBase;
  buildBase=function(prev){
   const w=oldBuildBase(prev);
   for(let di=0;di<6;di++){
    const missing=missingResponsibleCount(w,di);
    if(missing>=2)continue;
    const available=[...RESP].filter(n=>{
     const s=w.schedule[n]?.[di]||'—';
     return !PROTECTED_RESP.has(s)&&s!=='—'&&s!=='RIPOSO';
    });
    if(available.length<2)continue;
    let morning=available.find(n=>w.schedule[n][di]==='06:30-13:30')||available[0];
    let afternoon=available.find(n=>n!==morning&&w.schedule[n][di]==='13:30-20:30')||available.find(n=>n!==morning);
    if(!afternoon)continue;
    w.schedule[morning][di]='06:30-13:30';
    w.schedule[afternoon][di]='13:30-20:30';
    for(const n of available){
     if(n===morning||n===afternoon)continue;
     const s=w.schedule[n][di];
     if(isRespSplit(s))w.schedule[n][di]='06:30-13:30';
    }
   }
   return w;
  };
 }
})();