(()=>{
 const u=getSession();
 if(!u?.admin)return;
 let busy=false;
 function weekName(w){
  if(w?.label)return w.label;
  if(Array.isArray(w?.dates)&&w.dates.length)return `${fmtDate(w.dates[0])} – ${fmtDate(w.dates[w.dates.length-1])}`;
  return 'ultima settimana';
 }
 async function removeLastWeek(){
  if(busy)return;
  busy=true;
  const btn=document.getElementById('menuDeleteLastWeek');
  if(btn)btn.disabled=true;
  try{
   const data=await loadSchedule();
   if(!Array.isArray(data?.weeks)||!data.weeks.length){alert('Non ci sono settimane da eliminare.');return}
   const last=data.weeks[data.weeks.length-1],label=weekName(last);
   if(!confirm(`Vuoi eliminare l’ultima settimana pubblicata?\n\n${label}\n\nLe settimane precedenti resteranno intatte.`))return;
   if(!confirm(`Conferma definitiva:\nELIMINARE ${label}?`))return;
   const next=structuredClone(data);
   next.weeks=next.weeks.slice(0,-1);
   next.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());
   await api('save_schedule',{method:'POST',body:{data:next}});
   try{
    const pd=JSON.parse(localStorage.getItem('tm_planner_draft')||'null');
    if(pd?.week?.dates?.[0]===last?.dates?.[0])localStorage.removeItem('tm_planner_draft');
   }catch{}
   document.getElementById('homeMenuBack')?.remove();
   alert(`Settimana ${label} eliminata. Le settimane precedenti sono rimaste intatte.`);
   location.reload();
  }catch(e){alert(e?.message||'Impossibile eliminare la settimana.')}finally{busy=false;if(btn)btn.disabled=false}
 }
 function mount(){
  const menu=document.querySelector('#homeMenuBack .home-menu-list');
  if(!menu||document.getElementById('menuDeleteLastWeek'))return;
  const notify=document.getElementById('menuNotify');
  const sep=notify?.previousElementSibling;
  const b=document.createElement('button');
  b.id='menuDeleteLastWeek';b.type='button';b.className='menu-danger';
  b.innerHTML='<span class="ico">🗑️</span>Elimina ultima settimana';
  b.onclick=removeLastWeek;
  if(sep&&sep.classList.contains('menu-sep'))menu.insertBefore(b,sep);else if(notify)menu.insertBefore(b,notify);else menu.appendChild(b);
 }
 const obs=new MutationObserver(mount);obs.observe(document.documentElement,{childList:true,subtree:true});setTimeout(mount,0);
})();