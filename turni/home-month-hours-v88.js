(()=>{
'use strict';
const root=document.getElementById('app');if(!root)return;
const off=new Set(['RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—']);
function h(s){if(!s||off.has(s))return 0;return String(s).split('/').reduce((z,p)=>{const m=p.trim().match(/^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$/);if(!m)return z;const a=+m[1]*60 + +m[2],b=+m[3]*60 + +m[4];return z+Math.max(0,b-a)/60},0)}
function selectedYM(){try{return state?.data?.weeks?.[state.week]?.dates?.[0]?.slice(0,7)||null}catch{return null}}
function monthTotal(n,ym){if(!ym)return 0;let z=0;for(const w of state?.data?.weeks||[])for(let i=0;i<(w.dates||[]).length;i++)if(String(w.dates[i]).slice(0,7)===ym)z+=h(w.schedule?.[n]?.[i]);return Math.round(z*10)/10}
function weekTotal(n){try{const w=state.data.weeks[state.week];return Math.round((w.schedule?.[n]||[]).reduce((z,s)=>z+h(s),0)*10)/10}catch{return 0}}
function apply(){
 try{
  if(!state?.user?.admin||!state?.data?.weeks?.length)return;
  const ym=selectedYM();
  document.querySelectorAll('.admin-person').forEach(card=>{
   const n=card.querySelector('.admin-person-head strong')?.textContent?.trim();if(!n)return;
   const pill=card.querySelector('.hours-pill');if(pill){pill.textContent=`Sett. ${weekTotal(n)}h · Mese ${monthTotal(n,ym)}h`;pill.title='Ore della settimana selezionata e totale del mese'}
  });
  const table=document.querySelector('.admin-hours-details .hours-table');if(table){
   table.querySelectorAll('.hours-row').forEach(row=>{
    const n=row.querySelector('b')?.textContent?.trim();if(!n)return;
    let month=row.querySelector('.tm-month-total');if(!month){month=document.createElement('strong');month.className='tm-month-total';row.appendChild(month)}month.textContent=`Mese ${monthTotal(n,ym)}h`;
   });
  }
 }catch(e){console.warn('riepilogo ore mese',e)}
}
const st=document.createElement('style');st.textContent=`.admin-person .hours-pill{white-space:nowrap}.hours-row .tm-month-total{margin-left:auto;color:#003d7c;font-size:12px;background:#eef5fa;border-radius:999px;padding:5px 8px}@media(max-width:600px){.admin-person .hours-pill{font-size:9px}.hours-row .tm-month-total{font-size:10px}}`;document.head.appendChild(st);
let t=null;new MutationObserver(()=>{clearTimeout(t);t=setTimeout(apply,60)}).observe(root,{childList:true,subtree:true});window.addEventListener('load',()=>setTimeout(apply,250));
})();