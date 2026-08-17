(()=>{
 const originalRender=render;
 const originalFinish=finish;
 let firstAutoJump=true;
 function allIssues(){return candidate&&wi>=0?validateWeek(candidate.weeks[wi]):[]}
 function dayIssues(dayIndex){
   if(!candidate||wi<0)return[];
   const w=candidate.weeks[wi],prefix=fmtDate(w.dates[dayIndex])+':';
   return validateWeek(w).filter(x=>String(x).startsWith(prefix));
 }
 function issueDays(){
   if(!candidate||wi<0)return[];
   const w=candidate.weeks[wi],out=[];
   w.dates.forEach((_,i)=>{const list=dayIssues(i);if(list.length)out.push({i,list})});
   return out;
 }
 problems=function(){return dayIssues(di)};
 render=function(){
   if(firstAutoJump&&candidate&&wi>=0){
     const bad=issueDays();
     if(bad.length&&!bad.some(x=>x.i===di))di=bad[0].i;
     firstAutoJump=false;
   }
   originalRender();
   const main=document.querySelector('.review-main');
   if(!main||!candidate||wi<0)return;
   const w=candidate.weeks[wi],bad=issueDays();
   let nav=document.getElementById('errorDayNav');
   if(nav)nav.remove();
   const summary=document.querySelector('.request-summary');
   const bar=document.createElement('section');
   bar.id='errorDayNav';bar.className='error-day-nav';
   bar.innerHTML=bad.length?`<div class="error-day-label">Giorni con errori</div><div class="error-day-buttons">${bad.map(x=>`<button type="button" class="error-day-btn ${x.i===di?'active':''}" data-day="${x.i}"><b>${esc(fmtDate(w.dates[x.i]))}</b><span>${x.list.length} ${x.list.length===1?'errore':'errori'}</span></button>`).join('')}</div>`:`<div class="all-clear">✓ Tutti i giorni della settimana sono senza errori</div>`;
   summary?.insertAdjacentElement('afterend',bar);
   bar.querySelectorAll('[data-day]').forEach(b=>b.onclick=()=>{di=Number(b.dataset.day);firstAutoJump=false;render();window.scrollTo({top:0,behavior:'smooth'})});
   const issues=dayIssues(di),live=document.querySelector('.live-status');
   if(live&&issues.length){const label=fmtDate(w.dates[di]);live.innerHTML=`<b>Ci ${issues.length===1?'è 1 errore':'sono '+issues.length+' errori'} — accettare comunque?</b><div class="error-reason-slots">${issues.map(x=>`<div class="error-reason-slot">${esc(String(x).replace(label+': ',''))}</div>`).join('')}</div>`}
   const total=allIssues();
   const weeklyOnly=total.filter(x=>!w.dates.some(d=>String(x).startsWith(fmtDate(d)+':')));
   if(weeklyOnly.length){
     const note=document.createElement('div');note.className='weekly-issues';note.innerHTML=`<b>Controlli settimanali</b>${weeklyOnly.map(x=>`<div class="error-reason-slot">${esc(x)}</div>`).join('')}`;
     bar.insertAdjacentElement('afterend',note);
   }
 }
 finish=async function(force){
   const bad=issueDays();
   if(bad.length&&!force){di=bad[0].i;render();return}
   return originalFinish(force);
 }
 const style=document.createElement('style');style.textContent=`
 .error-day-nav{background:#fff;border:1px solid #dbe5ec;border-radius:17px;padding:11px;margin-bottom:10px}.error-day-label{font-size:11px;font-weight:950;color:#5d7280;text-transform:uppercase;margin-bottom:8px}.error-day-buttons{display:flex;flex-wrap:wrap;gap:8px}.error-day-btn{border:1px solid #e1c446;background:#fff6c8;color:#5f4e00;border-radius:12px;padding:9px 12px;text-align:left;min-width:120px}.error-day-btn b,.error-day-btn span{display:block}.error-day-btn b{color:#003d7c;font-size:12px}.error-day-btn span{font-size:10px;font-weight:900;margin-top:2px}.error-day-btn.active{background:#ffd500;border-color:#d4ad00;box-shadow:0 0 0 2px rgba(255,213,0,.22)}.all-clear{background:#ecf9ef;color:#17602a;border-radius:11px;padding:10px;font-weight:950}.weekly-issues{background:#eef5fa;border:1px solid #cbdde9;border-radius:14px;padding:10px 12px;margin-bottom:10px;color:#003d7c}.weekly-issues b{display:block;margin-bottom:6px}.error-reason-slots{display:grid;gap:6px;margin-top:8px}.error-reason-slot{background:rgba(255,255,255,.68);border:1px solid rgba(107,86,0,.18);border-radius:10px;padding:8px 10px;font-size:12px;font-weight:800}
 `;document.head.appendChild(style);
})();