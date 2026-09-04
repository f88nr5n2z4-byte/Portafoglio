(()=>{
'use strict';
const OLD_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-v2-api';
const CLEAN_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-api';
const SAFE_API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-safe-generate-v1';
const baseFetch=window.fetch.bind(window);
const ymd=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const addDays=(s,k)=>{const d=new Date(s+'T12:00:00');d.setDate(d.getDate()+k);return ymd(d)};
window.fetch=async function(input,init){
  try{
    const raw=typeof input==='string'?input:input?.url;
    const u=new URL(raw,location.href);
    if(u.origin+u.pathname===OLD_API&&u.searchParams.get('action')==='generate'){
      const body=JSON.parse(init?.body||'{}');
      const start=String(body.startDate||'');
      if(/^\d{4}-\d{2}-\d{2}$/.test(start)){
        const end=addDays(start,20);
        const headers=new Headers(init?.headers||{});
        if(!headers.has('Content-Type'))headers.set('Content-Type','application/json');
        const [ra,rr]=await Promise.all([
          baseFetch(`${CLEAN_API}?action=absences`,{method:'GET',headers}),
          baseFetch(`${CLEAN_API}?action=my_requests`,{method:'GET',headers})
        ]);
        if(ra.ok&&rr.ok){
          const a=await ra.json().catch(()=>({absences:[]}));
          const r=await rr.json().catch(()=>({requests:[]}));
          const hasAbs=(a.absences||[]).some(x=>x.date_from<=end&&x.date_to>=start);
          const hasReq=(r.requests||[]).some(x=>x.status==='ACCETTATA'&&['RIPOSO','TURNO'].includes(String(x.kind||'').toUpperCase())&&x.request_date>=start&&x.request_date<=end);
          if(!hasAbs&&!hasReq){
            return baseFetch(SAFE_API,{...(init||{}),method:'POST',headers,body:JSON.stringify({startDate:start})});
          }
        }
      }
    }
  }catch(e){console.warn('turni network fallback',e)}
  return baseFetch(input,init);
};
})();
