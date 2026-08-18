(()=>{
'use strict';
function refresh(){
 const btn=document.getElementById('v91Check');
 if(btn&&window.TM103){
  try{btn.click();document.documentElement.dataset.turniValidator='v103'}catch(e){console.warn('validator refresh v105',e)}
 }
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(refresh,0));else setTimeout(refresh,0);
setTimeout(refresh,150);
setTimeout(refresh,500);
})();
