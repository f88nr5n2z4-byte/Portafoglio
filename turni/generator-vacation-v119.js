(()=>{
'use strict';
const C=window.TM91,BASE=window.TM112,FLEX=window.TM_FLEX_SHIFTS_V118;
if(!C||!BASE)return;
const KEY='tm_v119_vacations';
const RESP=[...C.RESPONSABILI],CASH=[...C.CASSA],FLOOR=['Giuliano','Manuel','Daniele','Paolo'],ALL=[...RESP,...CASH,...C.SALA];
const TIMES=['06:45','07:00','10:00','13:30','16:30','17:00','19:59','20:29'];
const CONT=[...(FLEX?.continuous||[])];
const SPLITS=FLEX?.preferredVacationSplits||['07:00-13:00 / 17:00-20:00','07:00-13:00 / 17:00-20:30'];
const SOLO=FLEX?.responsibleSolo||'06:30-13:30 / 17:00-20:30';
const works=s=>C.works(s),hrs=s=>C.hours(s),at=(s,t)=>C.at(s,t),isSplit=s=>C.spans(s).length>1;
function loadVac(){try{const x=JSON.parse(localStorage.getItem(KEY)||'[]');return [0,1,2].map(i=>ALL.includes(x[i])?x[i]:'')}catch{return['','','']}}
function saveVac(v){localStorage.setItem(KEY,JSON.stringify(v))}
function lex(a,b){for(let i=0;i<a.length;i++){if(a[i]<b[i])return-1;if(a[i]>b[i])return 1}return 0}
function role(n){return RESP.includes(n)?'resp':CASH.includes(n)?'cash':FLOOR.includes(n)?'floor':n==='Marco'?'marco':''}
function minDaily(w,n){
 if(n==='Marco')return 4;
 const sun=w.dates.findIndex(C.isSunday),sunH=sun>=0?hrs(w.schedule[n]?.[sun]):0;
 return Math.max(0,(C.TARGET[n]-sunH)/5);
}
function optsFor(w,n,activeResp){
 const r=role(n),min=minDaily(w,n);
 if(r==='marco')return ['16:00-20:00','16:30-20:30'];
 let a=[];
 if(r==='resp'){
  if(activeResp===1)return [SOLO];
  a=['06:30-13:30','06:30-14:30','06:30-15:30','09:00-17:00','10:00-17:00','11:30-20:30','12:30-20:30','13:30-20:30'];
 }else if(r==='cash'){
  a=['07:00-14:00','07:00-15:00','09:00-17:00','10:00-17:00','12:30-20:30','13:30-20:30',...CONT,...SPLITS];
 }else if(r==='floor'){
  a=['06:30-13:30','06:30-14:30','06:30-15:30','09:00-17:00','10:00-17:00','12:30-20:30','13:30-20:30',...CONT,...SPLITS];
 }
 return [...new Set(a)].filter(s=>hrs(s)+1e-6>=min&&hrs(s)<=min+4.5);
}
function sig(s){return TIMES.map(t=>at(s,t)?1:0)}
function restPatterns(names,base){
 if(!names.length)return[{}];
 const out=[],seen=new Set();
 const add=o=>{const k=names.map(n=>o[n]).join(',');if(!seen.has(k)){seen.add(k);out.push(o)}};
 add(Object.fromEntries(names.map(n=>[n,base[n]])));
 const n=names.length;
 for(let off=0;off<6;off++){
  const a={},b={};
  names.forEach((p,i)=>{a[p]=(off+i*2)%6;b[p]=(off+i*2+((i%2)?1:0))%6});
  add(a);add(b);
 }
 return out.slice(0,14);
}
function solveDay(w,d,employees,marcoWork,priorOT,priorSplit,totalSplit){
 const activeResp=employees.filter(n=>RESP.includes(n)).length;
 const exact={1:4,5:marcoWork?5:4,6:marcoWork?5:4,7:4};
 let states=new Map();states.set('0,0,0,0,0,0,0,0|0,0,0,0,0',{cnt:[0,0,0,0,0,0,0,0],flags:[0,0,0,0,0],cost:[0,0,0,0],a:{},spl:0});
 for(const n of employees){
  const next=new Map(),options=optsFor(w,n,activeResp);
  for(const st of states.values())for(const s of options){
   const sp=isSplit(s)?1:0;
   if(sp&&n==='Marco')continue;
   if(sp&&(priorSplit[n]||0)>=1)continue;
   if(totalSplit+st.spl+sp>2)continue;
   const v=sig(s),cnt=st.cnt.map((x,i)=>x+v[i]);
   let bad=false;for(const [i,mx] of Object.entries(exact)){if(cnt[+i]>mx){bad=true;break}}if(bad)continue;
   const f=[...st.flags];if(CASH.includes(n)){if(v[1])f[0]=1;if(v[3])f[1]=1;if(v[7])f[2]=1}if(RESP.includes(n)&&v[0])f[3]=1;if(FLOOR.includes(n)&&v[0])f[4]=1;
   const base=minDaily(w,n),ot=n==='Marco'?0:Math.max(0,hrs(s)-base),po=priorOT[n]||0,ps=priorSplit[n]||0;
   const inc=[sp,(ps+sp)*(ps+sp)-ps*ps,(po+ot)*(po+ot)-po*po,ot];
   const cost=st.cost.map((x,i)=>x+inc[i]),a={...st.a,[n]:s},spl=st.spl+sp;
   const cap=cnt.map((x,i)=>[2,3,4].includes(i)?Math.min(5,x):x),key=cap.join(',')+'|'+f.join(',');
   const old=next.get(key);if(!old||lex(cost,old.cost)<0)next.set(key,{cnt,flags:f,cost,a,spl});
  }
  states=next;if(!states.size)return null;
 }
 let best=null;
 for(const st of states.values()){
  const c=st.cnt,f=st.flags;
  if(c[1]!==4||c[2]<5||c[3]<5||c[4]<5||c[5]!==exact[5]||c[6]!==exact[6]||c[7]!==4)continue;
  if(f.some(x=>!x))continue;
  if(!best||lex(st.cost,best.cost)<0)best=st;
 }
 return best;
}
function applyVacationWeek(w,vac){
 const original=JSON.parse(JSON.stringify(w.schedule));
 const vacRole=role(vac),group=vacRole==='resp'?RESP:vacRole==='cash'?CASH:vacRole==='floor'?FLOOR:[];
 if(!group.length&&vac!=='Marco')throw new Error('Ruolo ferie non riconosciuto per '+vac);
 const baseRest={};for(const n of group.filter(n=>n!==vac)){let r=0;for(let d=0;d<6;d++)if(original[n]?.[d]==='RIPOSO'){r=d;break}baseRest[n]=r}
 const patterns=vac==='Marco'?[{}]:restPatterns(group.filter(n=>n!==vac),baseRest);
 let chosen=null;
 for(const pattern of patterns){
  const temp=JSON.parse(JSON.stringify(original)),priorOT={},priorSplit={};let totalSplit=0,ok=true;
  temp[vac]=Array(7).fill('FERIE');
  for(let d=0;d<6;d++){
   const employees=[];
   for(const n of ALL){
    if(n===vac)continue;
    if(n==='Marco'){
     if(works(original[n]?.[d]))employees.push(n);
     continue;
    }
    if(group.includes(n)&&n!==vac){if(pattern[n]!==d)employees.push(n)}
    else if(works(original[n]?.[d]))employees.push(n);
   }
   const marcoWork=employees.includes('Marco');
   const sol=solveDay({...w,schedule:temp},d,employees,marcoWork,priorOT,priorSplit,totalSplit);
   if(!sol){ok=false;break}
   for(const n of ALL){if(n===vac){temp[n][d]='FERIE';continue}temp[n][d]=sol.a[n]||'RIPOSO'}
   for(const [n,s] of Object.entries(sol.a)){
    if(n==='Marco')continue;const ot=Math.max(0,hrs(s)-minDaily({...w,schedule:temp},n));priorOT[n]=(priorOT[n]||0)+ot;if(isSplit(s)){priorSplit[n]=(priorSplit[n]||0)+1;totalSplit++}
   }
  }
  if(!ok)continue;
  const sun=6;temp[vac][sun]='FERIE';
  if(works(original[vac]?.[sun])){
   const candidates=group.filter(n=>n!==vac&&!works(temp[n]?.[sun]));
   if(!candidates.length){continue}
   candidates.sort((a,b)=>C.weekHours({schedule:temp},a)-C.weekHours({schedule:temp},b));
   temp[candidates[0]][sun]='08:00-13:00';
  }
  const sc=group.filter(n=>n!==vac).reduce((z,n)=>z+(temp[n]||[]).filter(isSplit).length,0)+ALL.filter(n=>!group.includes(n)&&n!==vac).reduce((z,n)=>z+(temp[n]||[]).filter(isSplit).length,0);
  const ot=ALL.filter(n=>n!==vac&&n!=='Marco').reduce((z,n)=>z+Math.max(0,C.weekHours({schedule:temp},n)-C.TARGET[n]),0);
  const fairness=ALL.filter(n=>n!==vac&&n!=='Marco').map(n=>Math.max(0,C.weekHours({schedule:temp},n)-C.TARGET[n]));
  const score=[sc,Math.max(0,...fairness)-Math.min(0,...fairness),ot];
  if(!chosen||lex(score,chosen.score)<0)chosen={schedule:temp,score,ot,totalSplit:sc};
 }
 if(!chosen)throw new Error(`Nessuna soluzione valida con ${vac} in ferie mantenendo massimo 2 spezzati. Prova un'altra settimana o rimuovi le ferie.`);
 w.schedule=chosen.schedule;w.vacationEmployee=vac;w.vacationPolicy='v119';w.overtimeHours=chosen.ot;w.vacationSplits=chosen.totalSplit;return w;
}
function generate(start){
 const data=BASE.generate(start),v=loadVac();
 data.weeks.forEach((w,i)=>{if(v[i])applyVacationWeek(w,v[i])});
 data.generator='v119';return data;
}
function validateSchedule(data){
 const raw=BASE.validateSchedule(data),out=[];
 for(const e of raw){
  const w=data?.weeks?.[e.weekIndex],vac=w?.vacationEmployee;
  if(!vac){out.push(e);continue}
  if(e.type==='ore'&&e.employee===vac)continue;
  if(e.type==='riposi'&&e.employee===vac)continue;
  if(e.type==='spezzati'&&!e.employee)continue;
  if(e.type==='ore'&&e.employee&&e.employee!=='Marco'&&C.weekHours(w,e.employee)>=C.TARGET[e.employee]-1e-6)continue;
  out.push(e);
 }
 (data?.weeks||[]).forEach((w,wi)=>{
  const vac=w.vacationEmployee;if(!vac)return;
  if(!(w.schedule[vac]||[]).every(s=>s==='FERIE'))out.push({type:'ferie',weekIndex:wi,date:null,employee:vac,message:`${vac}: deve risultare FERIE per tutta la settimana`});
  const splits=ALL.reduce((z,n)=>z+(w.schedule[n]||[]).filter(isSplit).length,0);if(splits>2)out.push({type:'spezzati',weekIndex:wi,date:null,employee:null,message:`Settimana con ferie: ${splits} spezzati, massimo 2`});
  for(const n of ALL){if(n===vac)continue;const h=C.weekHours(w,n),t=C.TARGET[n];if(n==='Marco'){if(Math.abs(h-t)>.001)out.push({type:'ore',weekIndex:wi,date:null,employee:n,message:`Marco: ${h}h invece di ${t}h`})}else if(h<t-.001)out.push({type:'ore',weekIndex:wi,date:null,employee:n,message:`${n}: ${h}h, sotto le ${t}h previste`})}
 });
 return out;
}
function mount(){
 const host=document.querySelector('.v91controls')||document.querySelector('.card');if(!host||document.getElementById('vac119'))return;
 const v=loadVac(),box=document.createElement('div');box.id='vac119';box.innerHTML=`<div class="vac119-title">🏖️ Ferie nelle 3 settimane</div><div class="vac119-grid">${[0,1,2].map(i=>`<label>Settimana ${i+1}<select data-vac119="${i}"><option value="">Nessuna</option>${ALL.map(n=>`<option value="${n}" ${v[i]===n?'selected':''}>${n}</option>`).join('')}</select></label>`).join('')}</div><small>Con ferie: prima turni continui flessibili, massimo 2 spezzati, straordinari distribuiti a tutti tranne Marco.</small>`;
 host.appendChild(box);box.querySelectorAll('[data-vac119]').forEach(s=>s.onchange=()=>{const x=loadVac();x[+s.dataset.vac119]=s.value;saveVac(x)});
 }
 const css=document.createElement('style');css.textContent='#vac119{margin:12px 0;padding:12px;border:1px solid #dbe6ee;border-radius:14px;background:#f8fbfd}.vac119-title{font-weight:950;color:#003d7c;margin-bottom:9px}.vac119-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}.vac119-grid label{font-size:11px;font-weight:900;color:#587080}.vac119-grid select{display:block;width:100%;margin-top:4px;padding:9px;border:1px solid #c8d7e2;border-radius:10px;background:#fff}.vac119-grid+small{display:block;margin-top:8px;color:#6b7c87;font-size:10px}@media(max-width:650px){.vac119-grid{grid-template-columns:1fr}}';document.head.appendChild(css);
 new MutationObserver(mount).observe(document.getElementById('app')||document.documentElement,{childList:true,subtree:true});if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',mount);else mount();setTimeout(mount,100);
}
window.TM112={generate,validateSchedule};window.TM119={generate,validateSchedule,loadVacations:loadVac};
mount();
})();
