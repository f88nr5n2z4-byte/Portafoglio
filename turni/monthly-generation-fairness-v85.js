(()=>{
'use strict';
const nativeFetch=window.fetch.bind(window);
let patched=false;
const chooseOld="function choose(list,used,w,i){return list.filter(n=>!used.has(n)&&!PROT.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO'&&!works(w.schedule[n][i])).sort((a,b)=>remaining(w,b,i)-remaining(w,a,i)||N.indexOf(a)-N.indexOf(b))[0]||null}";
const chooseNew=`function generationBand(s){if(!works(s))return'off';if(at(s,'07:00')&&!at(s,'20:29'))return'morning';if(at(s,'20:29')||parts(s).some(([a])=>a>=hm('12:00')))return'afternoon';return'central'}
function generationBandCounts(w,n,i){let morning=0,afternoon=0;for(let k=0;k<i;k++){const b=generationBand(w.schedule[n][k]);if(b==='morning')morning++;else if(b==='afternoon')afternoon++}return{morning,afternoon}}
function generationFairScore(w,n,i,shift){if(!C.includes(n)&&!CB.includes(n))return 0;const b=generationBand(shift),z=generationBandCounts(w,n,i);if(b==='morning')return(z.morning-z.afternoon)*100;if(b==='afternoon')return(z.afternoon-z.morning)*100;return 0}
function choose(list,used,w,i){return list.filter(n=>!used.has(n)&&!PROT.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO'&&!works(w.schedule[n][i])).sort((a,b)=>remaining(w,b,i)-remaining(w,a,i)||N.indexOf(a)-N.indexOf(b))[0]||null}
function chooseFair(list,used,w,i,shift){return list.filter(n=>!used.has(n)&&!PROT.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO'&&!works(w.schedule[n][i])).sort((a,b)=>generationFairScore(w,a,i,shift)-generationFairScore(w,b,i,shift)||remaining(w,b,i)-remaining(w,a,i)||N.indexOf(a)-N.indexOf(b))[0]||null}`;
function patchSource(c){
 if(!c.includes(chooseOld))return c;
 c=c.replace(chooseOld,chooseNew);
 const reps=[
 ["mc=choose(C.filter(n=>available.includes(n)),used,w,i)||choose(CB.filter(n=>available.includes(n)),used,w,i)","mc=chooseFair(C.filter(n=>available.includes(n)),used,w,i,'07:00-14:00')||chooseFair(CB.filter(n=>available.includes(n)),used,w,i,'07:00-14:00')"],
 ["const n=choose([...C,...CB].filter(x=>available.includes(x)),used,w,i);if(n){set(w,n,i,'07:00-14:00')","const n=chooseFair([...C,...CB].filter(x=>available.includes(x)),used,w,i,'07:00-14:00');if(n){set(w,n,i,'07:00-14:00')"],
 ["const n=choose(S.filter(x=>available.includes(x)&&x!=='Marco'&&x!==mc),used,w,i);if(n){set(w,n,i,'06:30-13:30')","const n=chooseFair(S.filter(x=>available.includes(x)&&x!=='Marco'&&x!==mc),used,w,i,'06:30-13:30');if(n){set(w,n,i,'06:30-13:30')"],
 ["const n=choose(S.filter(x=>available.includes(x)&&x!=='Marco'&&x!==mc),used,w,i);if(!n)break;set(w,n,i,'07:00-14:00')","const n=chooseFair(S.filter(x=>available.includes(x)&&x!=='Marco'&&x!==mc),used,w,i,'07:00-14:00');if(!n)break;set(w,n,i,'07:00-14:00')"],
 ["ac=choose(C.filter(n=>available.includes(n)),used,w,i)||choose(CB.filter(n=>available.includes(n)),used,w,i)","ac=chooseFair(C.filter(n=>available.includes(n)),used,w,i,'13:30-20:30')||chooseFair(CB.filter(n=>available.includes(n)),used,w,i,'13:30-20:30')"],
 ["const n=choose([...C,...CB].filter(x=>available.includes(x)),used,w,i);if(n){set(w,n,i,'13:30-20:30')","const n=chooseFair([...C,...CB].filter(x=>available.includes(x)),used,w,i,'13:30-20:30');if(n){set(w,n,i,'13:30-20:30')"],
 ["const n=choose(available,used,w,i);if(!n)break;set(w,n,i,'13:30-20:30')","const n=chooseFair(available,used,w,i,'13:30-20:30');if(!n)break;set(w,n,i,'13:30-20:30')"]
 ];
 for(const [a,b] of reps)c=c.split(a).join(b);
 return c;
}
window.fetch=async function(input,init){
 const url=typeof input==='string'?input:(input?.url||'');
 if(!patched&&url.includes('monthly-turns-v62.js')){
  const r=await nativeFetch(input,init),text=patchSource(await r.text());patched=true;window.fetch=nativeFetch;
  return new Response(text,{status:r.status,statusText:r.statusText,headers:r.headers});
 }
 return nativeFetch(input,init);
};
})();