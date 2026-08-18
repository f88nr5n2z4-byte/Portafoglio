(()=>{
'use strict';
const FLAG='tm_seed_oct1_v80_done',KEY='tm_monthly_manual_overrides_v1';
try{
 const a=JSON.parse(localStorage.getItem(KEY)||'[]');
 if(Array.isArray(a)){
  const next=a.filter(x=>x?.source!=='schema richiesto 1 ottobre');
  if(next.length!==a.length)localStorage.setItem(KEY,JSON.stringify(next));
 }
 localStorage.removeItem(FLAG);
}catch{}
})();