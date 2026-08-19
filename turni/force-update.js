(()=>{
'use strict';
const VERSION='v137';
async function cleanup(){
 try{
  if('caches' in window){const keys=await caches.keys();await Promise.all(keys.map(k=>caches.delete(k)))}
  if('serviceWorker' in navigator){const reg=await navigator.serviceWorker.register(`sw.js?${VERSION}`,{scope:'./',updateViaCache:'none'});await reg.update()}
  localStorage.setItem('tm_runtime_version',VERSION);
 }catch(e){console.warn('runtime refresh',e)}
}
if(document.readyState==='complete')cleanup();else window.addEventListener('load',cleanup,{once:true});
})();