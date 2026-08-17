(()=>{
'use strict';
let dirty=false;
function ensureButton(){
 if(document.getElementById('tmApplyOptimizations'))return;
 const root=document.getElementById('app');if(!root)return;
 const btn=document.createElement('button');
 btn.id='tmApplyOptimizations';btn.type='button';btn.textContent='Applica correzioni e ricalcola';
 btn.style.cssText='position:fixed;right:14px;bottom:18px;z-index:15000;border:0;border-radius:14px;padding:13px 16px;background:#0067b1;color:#fff;font-weight:950;box-shadow:0 8px 24px rgba(0,0,0,.25);display:none';
 btn.onclick=()=>{btn.disabled=true;btn.textContent='Ricalcolo…';location.reload()};
 document.body.appendChild(btn);
}
window.tmOptimizationChanged=function(source='optimizer'){
 if(window.__tmFatal)return;
 dirty=true;window.__tmOptimizationDirty=true;ensureButton();
 const b=document.getElementById('tmApplyOptimizations');if(b){b.style.display='block';b.title='Correzioni pronte da '+source}
};
window.tmOptimizationStable=function(){
 ensureButton();
 if(!dirty){const b=document.getElementById('tmApplyOptimizations');if(b)b.style.display='none'}
};
window.addEventListener('load',()=>{ensureButton();window.tmOptimizationStable()});
})();