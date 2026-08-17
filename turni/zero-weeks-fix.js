(()=>{
 const originalRender=render;
 render=function(){
  const weeks=state?.data?.weeks;
  if(Array.isArray(weeks)&&weeks.length){
   state.week=Math.max(0,Math.min(state.week,weeks.length-1));
   return originalRender();
  }
  const u=state.user;
  app.innerHTML=`<div class="app-shell"><div class="brandbar"></div>${header(u)}<main class="main focused-main">${u?.admin?`<section class="admin-command"><span class="kicker">Pannello responsabile</span><h1>Torre Maura</h1><div class="admin-command-actions"><a href="inbox.html"><span>📥</span>Richieste${state.openRequests?`<em>${state.openRequests}</em>`:''}</a><a href="new-turns.html"><span>✨</span>Nuovi turni</a><a href="turnations.html"><span>📅</span>Turnazioni</a></div></section>`:''}<section class="schedule-focus zero-weeks"><span class="kicker">Turnazioni</span><h2>Nessuna settimana pubblicata</h2><p>Non ci sono settimane disponibili da mostrare. Puoi usare il menu per creare o gestire le turnazioni.</p></section></main></div>`;
  document.getElementById('logout')?.addEventListener('click',logout);
  document.getElementById('pushBtn')?.addEventListener('click',enablePush);
 };
 const style=document.createElement('style');style.textContent='.zero-weeks{margin-top:12px}.zero-weeks h2{color:var(--blue-deep);margin:5px 0 7px}.zero-weeks p{margin:0;color:var(--muted);font-size:13px}';document.head.appendChild(style);
})();