(()=>{
 const oldValidate=validateWeek;
 validateWeek=function(w){
  const issues=oldValidate(w);
  if(!w?.dates||!w?.schedule)return issues;
  const aft=weekAfternoonGroup(w);
  if(aft&&w.dates.length===7){
   for(const n of aft){
    const arr=w.schedule[n]||[];
    if(arr[6]==='RIPOSO'){
     const weekdayRest=arr.slice(0,6).findIndex(s=>s==='RIPOSO');
     if(weekdayRest>=0)issues.push(`${n}: riposa già domenica e non deve avere un secondo RIPOSO in settimana`);
    }
   }
  }
  return [...new Set(issues)];
 };

 if(typeof buildBase==='function'){
  const oldBuildBase=buildBase;
  buildBase=function(prev){
   const w=oldBuildBase(prev),aft=weekAfternoonGroup(w);
   if(aft&&w.dates.length===7){
    for(const n of aft){
     const arr=w.schedule[n]||[];
     if(arr[6]!=='RIPOSO')continue;
     for(let i=0;i<6;i++)if(arr[i]==='RIPOSO')arr[i]='14:00-20:00';
    }
   }
   return w;
  };
 }
})();