(()=>{
'use strict';
const VERSION='v142';
async function cleanup(){
 try{
  if('serviceWorker' in navigator){
   const regs=await navigator.serviceWorker.getRegistrations();
   await Promise.all(regs.map(r=>r.unregister()));
  }
  if('caches' in window){
   const keys=await caches.keys();
   await Promise.all(keys.map(k=>caches.delete(k)));
  }
  const prev=localStorage.getItem('tm_runtime_version');
  localStorage.setItem('tm_runtime_version',VERSION);
  if(prev!==VERSION){
   const u=new URL(location.href);
   if(u.searchParams.get('_rt')!==VERSION){
    u.searchParams.set('_rt',VERSION);
    location.replace(u.toString());
   }
  }
 }catch(e){console.warn('runtime reset',e)}
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',cleanup,{once:true});else cleanup();
})();