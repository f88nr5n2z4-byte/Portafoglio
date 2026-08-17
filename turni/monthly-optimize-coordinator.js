(()=>{
'use strict';
const KEY='tm_optimize_round_v76';
let timer=null;
window.tmOptimizationChanged=function(source='optimizer'){
 if(window.__tmFatal)return;
 window.__tmOptimizationDirty=true;
 clearTimeout(timer);
 timer=setTimeout(()=>{
  const n=Number(sessionStorage.getItem(KEY)||0);
  if(n>=2){console.warn('Ottimizzazione fermata dopo 2 ricalcoli',source);return}
  sessionStorage.setItem(KEY,String(n+1));
  location.replace(location.pathname+'?v=76&opt='+(n+1)+'&t='+Date.now());
 },900);
};
window.tmOptimizationStable=function(){
 setTimeout(()=>{
  if(!window.__tmOptimizationDirty)sessionStorage.removeItem(KEY);
 },2500);
};
window.addEventListener('load',()=>window.tmOptimizationStable());
})();