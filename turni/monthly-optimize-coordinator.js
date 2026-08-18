(()=>{
'use strict';
let dirty=false;
function ensureButton(){
 const root=document.getElementById('app');if(!root)return null;
 let wrap=document.getElementById('tmApplyOptimizationsWrap'),btn=document.getElementById('tmApplyOptimizations');
 const control=[...root.querySelectorAll('.card')].find(c=>c.querySelector('h3')?.textContent.includes('Controllo finale'));
 if(!wrap){wrap=document.createElement('div');wrap.id='tmApplyOptimizationsWrap';wrap.style.cssText='margin-top:10px;display:none';btn=document.createElement('button');btn.id='tmApplyOptimizations';btn.type='button';btn.textContent='Applica correzioni e ricalcola';btn.style.cssText='width:100%;border:0;border-radius:13px;padding:13px 16px;background:#0067b1;color:#fff;font-weight:950';btn.onclick=()=>{btn.disabled=true;btn.textContent='Ricalcolo…';location.reload()};wrap.appendChild(btn)}
 if(control&&!control.contains(wrap))control.appendChild(wrap);else if(!control&&!wrap.isConnected)root.appendChild(wrap);
 return btn;
}
window.tmOptimizationChanged=function(source='optimizer'){if(window.__tmFatal)return;dirty=true;window.__tmOptimizationDirty=true;const b=ensureButton(),w=document.getElementById('tmApplyOptimizationsWrap');if(b&&w){w.style.display='block';b.title='Correzioni pronte da '+source}}
window.tmOptimizationStable=function(){const b=ensureButton(),w=document.getElementById('tmApplyOptimizationsWrap');if(!dirty&&b&&w)w.style.display='none'};
const mo=new MutationObserver(()=>ensureButton());mo.observe(document.getElementById('app'),{childList:true,subtree:true});window.addEventListener('load',()=>{ensureButton();window.tmOptimizationStable()});
})();