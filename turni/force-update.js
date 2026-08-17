(()=>{
 if(!('serviceWorker' in navigator))return;
 const KEY='tm_force_sw_v56';
 window.addEventListener('load',async()=>{
  try{
   const reg=await navigator.serviceWorker.register('sw.js?v=56',{scope:'./'});
   await reg.update();
   if(!localStorage.getItem(KEY)){
    localStorage.setItem(KEY,'1');
    const reload=()=>location.reload();
    if(reg.waiting){reg.waiting.postMessage?.({type:'SKIP_WAITING'});setTimeout(reload,250)}
    else navigator.serviceWorker.addEventListener('controllerchange',reload,{once:true});
   }
  }catch(e){console.warn('force sw update',e)}
 });
})();