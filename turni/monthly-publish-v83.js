(()=>{
'use strict';
const ROOT=document.getElementById('app');if(!ROOT)return;
const N=['Umberto','Fabio','Emanuele','Stefania B','Giada','Giuliano','Daniele','Manuel','Romina','Stefania F','Paolo','Marco'];
function state(){try{return JSON.parse(localStorage.getItem('tm_planner_draft')||'null')?.week||null}catch{return null}}
function iso(d){return d.toLocaleDateString('sv-SE')}
function monday(d){const x=new Date(d+'T12:00:00'),k=(x.getDay()+6)%7;x.setDate(x.getDate()-k);return iso(x)}
function weekObj(k,w,old){const idx=[];w.dates.forEach((d,i)=>{if(monday(d)===k)idx.push(i)});const dd=idx.map(i=>w.dates[i]),all=[...new Set([...(old?.dates||[]),...dd])].sort(),schedule={};for(const n of N)schedule[n]=all.map(d=>{const di=w.dates.indexOf(d);if(di>=0)return w.schedule?.[n]?.[di]||'—';const oi=old?.dates?.indexOf(d)??-1;return oi>=0?old.schedule?.[n]?.[oi]||'—':'—'});return{label:`${all[0]} / ${all.at(-1)}`,dates:all,schedule,period:'week',sourceMonth:`${w.year}-${String(w.month).padStart(2,'0')}`}}
async function publishCurrent(btn){
 btn.disabled=true;const oldText=btn.textContent;btn.textContent='Controllo…';
 try{
  if(typeof window.tmRunAudit==='function')await window.tmRunAudit();
  const blocking=ROOT.querySelector('.extra-audit.statusbad');
  if(blocking){alert('Ci sono ancora errori realmente bloccanti nel Controllo definitivo. Controlla solo quelli rossi.');return}
  const w=state();if(!w?.dates?.length)throw new Error('Bozza non trovata');
  btn.textContent='Pubblicazione…';
  let official={weeks:[]};const s=await api('get_schedule');if(s.data&&Array.isArray(s.data.weeks))official=s.data;
  const data=structuredClone(official||{weeks:[]});data.weeks=Array.isArray(data.weeks)?data.weeks:[];
  const keys=[...new Set(w.dates.map(monday))];
  for(const k of keys){
   const overlaps=data.weeks.filter(pw=>(pw.dates||[]).some(d=>monday(d)===k));let merged=null;
   if(overlaps.length){const dates=[...new Set(overlaps.flatMap(pw=>pw.dates||[]))].sort(),schedule={};for(const n of N)schedule[n]=dates.map(d=>{for(const pw of overlaps){const i=(pw.dates||[]).indexOf(d);if(i>=0)return pw.schedule?.[n]?.[i]||'—'}return'—'});merged={dates,schedule}}
   data.weeks=data.weeks.filter(pw=>!overlaps.includes(pw));data.weeks.push(weekObj(k,w,merged));
  }
  data.weeks.sort((a,b)=>String(a.dates?.[0]||'').localeCompare(String(b.dates?.[0]||'')));
  data.updated=new Intl.DateTimeFormat('it-IT',{dateStyle:'long',timeStyle:'short'}).format(new Date());
  await api('save_schedule',{method:'POST',body:{data}});
  localStorage.removeItem('tm_planner_draft');
  alert('Turni pubblicati correttamente dalla bozza attuale.');location.href='index.html';
 }catch(e){console.error(e);alert('Pubblicazione non riuscita: '+(e?.message||e))}
 finally{if(document.body.contains(btn)){btn.disabled=false;btn.textContent=oldText}}
}
function install(){
 const actions=ROOT.querySelector('.actions');if(!actions)return;
 let old=actions.querySelector('.publish');if(!old)return;
 if(old.dataset.currentPublisher==='1')return;
 const btn=old.cloneNode(true);btn.disabled=false;btn.id='publish';btn.dataset.currentPublisher='1';btn.textContent='Pubblica turni';
 old.replaceWith(btn);btn.addEventListener('click',e=>{e.preventDefault();e.stopImmediatePropagation();publishCurrent(btn)},true);
}
let timer=null;new MutationObserver(()=>{clearTimeout(timer);timer=setTimeout(install,80)}).observe(ROOT,{childList:true,subtree:true});window.addEventListener('load',()=>setTimeout(install,500));window.addEventListener('tm:draft-changed',()=>setTimeout(install,80));setTimeout(install,900);
})();