(()=>{
'use strict';
const OLD_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-v2-api';
const CLEAN_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-api';
const nativeFetch=window.fetch.bind(window);
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function fetchWithRetry(url,init,tries=2){
 let lastErr=null;
 for(let i=0;i<tries;i++){
  try{
   const r=await nativeFetch(url,init);
   if(r.status!==546&&r.status!==502&&r.status!==503&&r.status!==504)return r;
   if(i===tries-1)return r;
  }catch(e){lastErr=e;if(i===tries-1)throw e}
  await wait(700*(i+1));
 }
 if(lastErr)throw lastErr;
 return nativeFetch(url,init);
}
window.fetch=function(input,init){
 try{
  const raw=typeof input==='string'?input:input?.url;
  const u=new URL(raw,location.href);
  if(u.origin+u.pathname===OLD_API){
   const target=new URL(CLEAN_API);
   target.search=u.search;
   if(u.searchParams.get('action')==='generate')return fetchWithRetry(target.toString(),init,2);
   return nativeFetch(target.toString(),init);
  }
 }catch{}
 return nativeFetch(input,init);
};
})();
