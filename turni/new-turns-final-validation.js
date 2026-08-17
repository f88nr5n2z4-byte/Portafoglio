(()=>{
 let ready=false,timer=null,lastUsed=[];
 const previousDraw=draw;
 function showChecking(){
  const main=document.querySelector('.nt');if(!main)return;
  const card=[...main.querySelectorAll('.card')].find(c=>c.querySelector('h3')?.textContent.trim()==='Controllo regole');
  const box=card?.querySelector('.statusok,.statusbad,.statuschecking');
  if(box){box.className='statuschecking';box.textContent='⏳ Controllo completo: 5 verifiche di tutte le regole…'}
  const actions=main.querySelector('.actions');if(actions)actions.innerHTML='<button type="button" disabled class="validation-wait">5 controlli completi in corso…</button>';
 }
 function fivePassIssues(){
  let last=[];
  for(let pass=1;pass<=5;pass++)last=validateWeek(draft);
  return last;
 }
 function persistFinal(){
  try{const issues=fivePassIssues();localStorage.setItem('tm_planner_draft',JSON.stringify({week:draft,issues,validationPasses:5,createdAt:new Date().toISOString()}));return issues}catch{return['Errore durante i 5 controlli finali']}
 }
 function finalize(){
  if(!draft)return;
  ready=true;persistFinal();previousDraw(lastUsed||[]);
 }
 draw=function(used){
  lastUsed=Array.isArray(used)?used:lastUsed;
  previousDraw(used);showChecking();
  clearTimeout(timer);timer=setTimeout(finalize,260);
 };
 const style=document.createElement('style');style.textContent=`.statuschecking{background:#eef5fa;border:1px solid #b9cede;color:#31566f;border-radius:14px;padding:12px;font-weight:900}.validation-wait{border:1px solid #c9d8e3;background:#eef3f6;color:#657985;border-radius:13px;padding:13px;font-weight:900}`;document.head.appendChild(style);
})();