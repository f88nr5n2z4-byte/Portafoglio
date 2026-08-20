(()=>{
'use strict';
const OLD_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-v2-api';
const CLEAN_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-api';
const DIVERSE_GENERATOR='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-diverse-v1';
const nativeFetch=window.fetch.bind(window);
window.fetch=function(input,init){
 try{
  const raw=typeof input==='string'?input:input?.url;
  const u=new URL(raw,location.href);
  if(u.origin+u.pathname===OLD_API){
   if(u.searchParams.get('action')==='generate')return nativeFetch(DIVERSE_GENERATOR,init);
   const target=new URL(CLEAN_API);
   target.search=u.search;
   return nativeFetch(target.toString(),init);
  }
 }catch{}
 return nativeFetch(input,init);
};
})();
