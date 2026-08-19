(()=>{
 'use strict';
 const style=document.createElement('style');
 style.textContent='button,a,summary,[role="button"],.navcard,.chip,.v91shift,.nt132-shift{touch-action:manipulation;-webkit-user-select:none;user-select:none}button:not(:disabled),a,summary,[role="button"]{pointer-events:auto}';
 document.head.appendChild(style);
 let touch=null;
 document.addEventListener('touchstart',e=>{if(e.touches.length!==1){touch=null;return}const t=e.touches[0];touch={x:t.clientX,y:t.clientY}}, {passive:true,capture:true});
 document.addEventListener('touchend',e=>{
  if(!touch||!e.changedTouches?.length)return;
  const t=e.changedTouches[0],dx=Math.abs(t.clientX-touch.x),dy=Math.abs(t.clientY-touch.y);touch=null;
  if(dx>12||dy>12)return;
  const el=e.target?.closest?.('button:not(:disabled),a[href],summary,[role="button"],.navcard,.chip,.v91shift,.nt132-shift');
  if(!el)return;
  e.preventDefault();
  setTimeout(()=>el.click(),0);
 }, {passive:false,capture:true});
 if(!('serviceWorker' in navigator))return;
 const KEY='tm_force_sw_v133';
 window.addEventListener('load',async()=>{
  try{
   const reg=await navigator.serviceWorker.register('sw.js?v=133',{scope:'./'});
   await reg.update();
   localStorage.setItem(KEY,'1');
  }catch(e){console.warn('force sw update',e)}
 });
})();