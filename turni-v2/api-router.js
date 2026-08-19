(()=>{
'use strict';
const MANAGEMENT='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-v2-api';
const GENERATOR='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-v2-generate-v11';
const nativeFetch=window.fetch.bind(window);
window.fetch=function(input,init){
 try{
  const raw=typeof input==='string'?input:input?.url;
  const u=new URL(raw,location.href);
  if(u.origin+u.pathname===MANAGEMENT&&u.searchParams.get('action')==='generate'){
   return nativeFetch(GENERATOR,init);
  }
 }catch{}
 return nativeFetch(input,init);
};
})();
