(()=>{
 if(!('serviceWorker' in navigator))return;
 const KEY='tm_force_sw_v113';
 window.addEventListener('load',async()=>{
  try{
   const reg=await navigator.serviceWorker.register('sw.js?v=113',{scope:'./'});
   await reg.update();
   if(!localStorage.getItem(KEY))localStorage.setItem(KEY,'1');
  }catch(e){console.warn('force sw update',e)}
 });
})();