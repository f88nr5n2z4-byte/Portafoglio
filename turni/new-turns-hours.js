(()=>{
 const oldRepair=repair;
 const SIMPLE=['06:30-13:30','07:00-14:00','09:00-14:00','10:00-17:00','11:00-18:00','11:00-20:30','12:00-20:30','13:30-20:30','14:00-20:00','14:00-20:30','16:00-20:00'];
 const protectedAbsence=arr=>(arr||[]).some(s=>['FERIE','MALATTIA','MATERNITÀ','PERMESSO'].includes(s));
 function wanted(n){return target(n)}
 function hourPenalty(w){
  let p=0;
  for(const n of Object.keys(w.schedule||{})){
   const arr=w.schedule[n]||[];
   if(protectedAbsence(arr))continue;
   p+=Math.abs(weekHours(w,n)-wanted(n));
  }
  return p;
 }
 function splitCount(w){let n=0;for(const a of Object.values(w.schedule||{}))for(const s of a||[])if(String(s||'').includes('/'))n++;return n}
 function score(w){return [validateWeek(w).length,hourPenalty(w),splitCount(w)]}
 function better(a,b){return a[0]<b[0]||(a[0]===b[0]&&(a[1]<b[1]||(a[1]===b[1]&&a[2]<b[2])))}
 function options(name,old){
  if(RESP.has(name))return [old,'06:30-13:30','13:30-20:30'];
  if(CASH.has(name))return [old,'06:30-13:30','07:00-14:00','09:00-14:00','11:00-20:30','13:30-20:30','14:00-20:30'];
  return [old,...SIMPLE];
 }
 function balance(w){
  if(!w?.schedule)return w;
  for(let pass=0;pass<20;pass++){
   const base=score(w);let best=null;
   for(let di=0;di<Math.min(6,w.dates?.length||0);di++){
    for(const name of Object.keys(w.schedule)){
     if(typeof locked!=='undefined'&&locked.has(`${name}|${di}`))continue;
     const old=w.schedule[name][di];
     if(ABSENCES.has(old))continue;
     for(const s of [...new Set(options(name,old))]){
      if(s===old||ABSENCES.has(s))continue;
      w.schedule[name][di]=s;
      const sc=score(w);
      if(better(sc,base)&&(!best||better(sc,best.score)))best={name,di,s,old,score:sc};
     }
     w.schedule[name][di]=old;
    }
   }
   if(!best)break;
   w.schedule[best.name][best.di]=best.s;
  }
  return w;
 }
 repair=function(w){return balance(oldRepair(w))};
})();