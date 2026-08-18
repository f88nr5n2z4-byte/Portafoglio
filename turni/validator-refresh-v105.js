(()=>{
'use strict';
function refresh(){
 const btn=document.getElementById('v91Check');
 if(btn&&window.TM112){
  try{
   btn.click();
   document.documentElement.dataset.turniValidator='v112';
  }catch(e){console.warn('validator refresh v114',e)}
 }
}
function run(){setTimeout(refresh,0);setTimeout(refresh,120);setTimeout(refresh,400);}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run);else run();
})();
