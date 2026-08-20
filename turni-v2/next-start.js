(()=>{
'use strict';
const API='https://dlqrhteqodkdkvmrwktu.supabase.co/functions/v1/turni-clean-api';
const token=()=>localStorage.getItem('tm2_token')||'';
const user=()=>{try{return JSON.parse(localStorage.getItem('tm2_user')||'{}')}catch{return{}}};
const ymd=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
function calendarNextMonday(){const d=new Date();d.setHours(12,0,0,0);let k=(8-d.getDay())%7;if(!k)k=7;d.setDate(d.getDate()+k);return ymd(d)}
function dayAfter(s){const d=new Date(`${s}T12:00:00`);d.setDate(d.getDate()+1);return ymd(d)}
let busy=false,lastInput=null;
async function apply(){
 if(location.hash!=='#generate'||user()?.role!=='admin'||busy)return;
 const input=document.getElementById('startDate');
 if(!input||input===lastInput)return;
 lastInput=input;
 const original=input.value;
 if(original&&original!==calendarNextMonday())return;
 busy=true;
 try{
  const r=await fetch(`${API}?action=get_schedule`,{headers:{Authorization:`Bearer ${token()}`}});
  const d=await r.json().catch(()=>({}));
  const end=d?.schedule?.end_date||d?.schedule?.data?.endDate;
  if(!r.ok||!end)return;
  const next=dayAfter(end);
  input.value=next;
  input.dataset.autoAfterPublished='1';
  input.dispatchEvent(new Event('change',{bubbles:true}));
  for(const id of ['qrRestDate','qrShiftDate']){
   const x=document.getElementById(id);
   if(x&&(!x.value||x.value===original))x.value=next;
  }
  let note=document.getElementById('nextPublishedNote');
  if(!note){note=document.createElement('small');note.id='nextPublishedNote';note.style.display='block';note.style.marginTop='4px';note.style.opacity='.72';input.closest('.field')?.appendChild(note)}
  note.textContent=`Impostato automaticamente dopo gli ultimi turni pubblicati (${end}).`;
 }finally{busy=false}
}
new MutationObserver(()=>setTimeout(apply,30)).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('hashchange',()=>{lastInput=null;setTimeout(apply,60)});
setTimeout(apply,250);
})();
