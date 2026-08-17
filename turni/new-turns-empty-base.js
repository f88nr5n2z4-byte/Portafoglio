(()=>{
 const originalApi=api;
 loadSchedule=async function(){
  try{
   const r=await originalApi('get_schedule');
   if(r?.data&&Array.isArray(r.data.weeks)){
    if(r.data.weeks.length)return r.data;
    const seed=await fetch('generator-seed.json',{cache:'no-store'}).then(x=>x.json());
    const base=structuredClone(seed?.weeks?.at(-1));
    if(!base)return {...r.data,weeks:[]};
    base.__technicalSeed=true;
    return {...r.data,weeks:[base],__emptyOriginal:true};
   }
  }catch(e){console.warn('empty schedule base',e)}
  return {weeks:[]};
 };
 api=async function(action,opts={}){
  if(action==='save_schedule'&&opts?.body?.data&&Array.isArray(opts.body.data.weeks)){
   const clean=structuredClone(opts);
   clean.body.data.weeks=clean.body.data.weeks.filter(w=>!w?.__technicalSeed);
   delete clean.body.data.__emptyOriginal;
   return originalApi(action,clean);
  }
  return originalApi(action,opts);
 };
})();