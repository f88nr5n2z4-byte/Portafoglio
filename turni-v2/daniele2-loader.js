(()=>{
'use strict';
const PATCHED=new Set(['api-router.js','app.js','alt-generator.js','one-ferie-generator.js','quick-requests.js','ferie-button.js','admin-tools.js']);
const FILES=['api-router.js','network-fallback.js','app.js','alt-generator.js','one-ferie-generator.js','request-management.js','quick-requests.js','ferie-button.js','admin-tools.js','delete-weeks.js','notifications.js','next-start.js'];
function patch(src){
  return src
    .replace(/Marco/g,'Daniele2')
    .replace(/Daniele2:16/g,'Daniele2:30')
    .replace(/Daniele2:'Sala \/ Jolly'/g,"Daniele2:'Sala'");
}
async function load(name){
  const r=await fetch(`./${name}?v=daniele2-src-20260904`,{cache:'no-store'});
  if(!r.ok)throw new Error(`Impossibile caricare ${name}`);
  let src=await r.text();
  if(PATCHED.has(name))src=patch(src);
  (0,eval)(`${src}\n//# sourceURL=${name}`);
}
(async()=>{
  try{
    for(const f of FILES)await load(f);
  }catch(e){
    console.error('Daniele2 loader',e);
    const app=document.getElementById('app');
    if(app)app.innerHTML=`<div class="boot"><div class="logo">E</div><strong>Errore caricamento</strong><span>${String(e?.message||e)}</span></div>`;
  }
})();
})();
