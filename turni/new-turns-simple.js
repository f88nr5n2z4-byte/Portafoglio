(()=>{
 const originalRepair=repair;
 const SIMPLE=['06:30-13:30','07:00-14:00','09:00-14:00','10:00-17:00','11:00-18:00','13:30-20:30','14:00-20:00','14:00-20:30','16:00-20:00','08:00-13:00'];
 function splitCount(w){let n=0;for(const arr of Object.values(w.schedule||{}))for(const s of arr||[])if(String(s||'').includes('/'))n++;return n}
 function simplify(w){
  if(!w?.schedule)return w;
  let baseIssues=validateWeek(w).length;
  let changed=true;
  while(changed){
   changed=false;
   const baseSplits=splitCount(w);
   outer:for(let di=0;di<7;di++)for(const name of Object.keys(w.schedule)){
    if(locked.has(`${name}|${di}`))continue;
    const old=w.schedule[name][di];
    if(!String(old||'').includes('/'))continue;
    const opts=RESP.has(name)?['06:30-13:30','13:30-20:30','08:00-13:00']:CASH.has(name)?['06:30-13:30','07:00-14:00','09:00-14:00','13:30-20:30','14:00-20:30','08:00-13:00']:SIMPLE;
    for(const s of opts){
     w.schedule[name][di]=s;
     const issues=validateWeek(w).length,splits=splitCount(w);
     if(issues<=baseIssues&&splits<baseSplits){baseIssues=issues;changed=true;break outer}
    }
    w.schedule[name][di]=old;
   }
  }
  return w;
 }
 repair=function(w){const out=originalRepair(w);return simplify(out)};
})();