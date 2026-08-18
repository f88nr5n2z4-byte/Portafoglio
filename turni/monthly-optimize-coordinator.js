(()=>{
'use strict';
let dirty=false;
function ensureButton(){
 const root=document.getElementById('app');if(!root)return null;
 let wrap=document.getElementById('tmApplyOptimizationsWrap'),btn=document.getElementById('tmApplyOptimizations');
 const control=[...root.querySelectorAll('.card')].find(c=>c.querySelector('h3')?.textContent.includes('Controllo finale'));
 if(!wrap){
  wrap=document.createElement('div');wrap.id='tmApplyOptimizationsWrap';wrap.style.cssText='margin-top:10px;display:block';
  btn=document.createElement('button');btn.id='tmApplyOptimizations';btn.type='button';btn.textContent='Ricontrolla bozza';
  btn.style.cssText='width:100%;border:0;border-radius:13px;padding:13px 16px;background:#0067b1;color:#fff;font-weight:950';
  btn.onclick=async()=>{btn.disabled=true;const old=btn.textContent;btn.textContent='Ricontrollo…';window.dispatchEvent(new CustomEvent('tm:draft-changed',{detail:{source:'ricontrollo-manuale'}}));try{await window.tmRunAudit?.()}finally{setTimeout(()=>{btn.disabled=false;btn.textContent=old},250)}};
  wrap.appendChild(btn)
 }
 if(control&&!control.contains(wrap))control.appendChild(wrap);else if(!control&&!wrap.isConnected)root.appendChild(wrap);
 return btn;
}
window.tmOptimizationChanged=function(source='optimizer'){if(window.__tmFatal)return;dirty=true;window.__tmOptimizationDirty=true;const b=ensureButton();if(b)b.title='Ricontrolla la bozza attuale senza ricaricare la pagina. Suggerimenti da '+source}
window.tmOptimizationStable=function(){ensureButton()};
const mo=new MutationObserver(()=>ensureButton());mo.observe(document.getElementById('app'),{childList:true,subtree:true});window.addEventListener('load',()=>{ensureButton();window.tmOptimizationStable()});
})();