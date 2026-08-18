(()=>{
'use strict';
if(new URLSearchParams(location.search).get('errors')!=='1')return;
const app=document.getElementById('app');if(!app)return;
function apply(){
 const main=app.querySelector('.ta');if(!main)return;
 const head=main.querySelector('.ta-head strong');if(head)head.textContent='Errori turnazione';
 const boxes=[...main.querySelectorAll('.weekbox')];
 let visible=0;
 for(const box of boxes){
  const bad=box.querySelector('.badcount');
  const has=!!bad&&/erro/i.test(bad.textContent||'');
  box.style.display=has?'':'none';
  if(has){box.open=true;visible++}
 }
 let empty=main.querySelector('#turnationErrorsEmpty');
 if(!visible){
  if(!empty){empty=document.createElement('section');empty.id='turnationErrorsEmpty';empty.className='weekbox';empty.innerHTML='<div style="padding:18px" class="ok">✓ Nessun errore turnazione da controllare.</div>';const h=main.querySelector('.ta-head');h?.insertAdjacentElement('afterend',empty)}
 }else empty?.remove();
}
let t=null;new MutationObserver(()=>{clearTimeout(t);t=setTimeout(apply,40)}).observe(app,{childList:true,subtree:true});window.addEventListener('load',()=>setTimeout(apply,120));setTimeout(apply,250);
})();