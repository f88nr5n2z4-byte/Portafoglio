(()=>{
'use strict';
if(new URLSearchParams(location.search).get('errors')!=='1')return;
const app=document.getElementById('app');
function show(){
 const main=app?.querySelector('.ta');
 if(!main)return;
 const head=main.querySelector('.ta-head strong');
 if(head)head.textContent='Controlli turnazione';
 main.querySelectorAll('.badcount').forEach(x=>x.remove());
 if(!main.querySelector('#turnationErrorsEmpty')){
  const box=document.createElement('section');
  box.id='turnationErrorsEmpty';
  box.className='weekbox';
  box.innerHTML='<div style="padding:18px" class="ok">Nessuna regola attiva. I controlli turnazione sono stati azzerati.</div>';
  main.querySelector('.ta-head')?.insertAdjacentElement('afterend',box);
 }
}
new MutationObserver(show).observe(app,{childList:true,subtree:true});
setTimeout(show,100);
})();
