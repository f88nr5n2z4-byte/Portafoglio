(()=>{
'use strict';
const CONSTRAINED=window.TM112,NORMAL=window.TM_TEMPLATE_BASE_V139,BAL=window.TM_BALANCE_V139;if(!CONSTRAINED||!NORMAL||!BAL)return;
const REQ='tm_v125_requests',ABS='tm_v125_absences',ROT='tm_rotation_v125';
const MONTHS={gen:0,feb:1,mar:2,apr:3,mag:4,giu:5,lug:6,ago:7,set:8,ott:9,nov:10,dic:11};
const iso=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
function load(k,def){try{return JSON.parse(localStorage.getItem(k)||JSON.stringify(def))}catch{return def}}
function monday(start){const d=new Date(start+'T12:00:00'),k=(d.getDay()+6)%7;d.setDate(d.getDate()-k);return d}
function range(start){const a=monday(start),b=new Date(a);b.setDate(a.getDate()+20);return[iso(a),iso(b)]}
function reqDate(x){const g=String(x?.message||'').match(/Giorno:\s*([^\n]+)/);if(!g)return null;const m=g[1].toLowerCase().match(/(?:lun|mar|mer|gio|ven|sab|dom)?\s*(\d{1,2})\s+([a-zà]+)/i);if(!m)return null;const mon=MONTHS[m[2].slice(0,3)];if(mon===undefined)return null;const base=x.created_at?new Date(x.created_at):new Date(),ys=[base.getFullYear()-1,base.getFullYear(),base.getFullYear()+1];let best=null,z=Infinity;for(const y of ys){const d=new Date(y,mon,+m[1],12),q=Math.abs(d-base);if(q<z){best=d;z=q}}return best?iso(best):null}
function changedRotation(){const r=load(ROT,{});return Object.values(r||{}).some(g=>g&&Object.entries(g).some(([k,v])=>v&&v!==k))}
function hasConstraints(start){const[from,to]=range(start),req=load(REQ,[]),abs=load(ABS,[]);return req.some(x=>x?.status==='ACCETTATA'&&(()=>{const d=reqDate(x);return d&&d>=from&&d<=to})())||abs.some(x=>x?.from&&x?.to&&x.to>=from&&x.from<=to)||changedRotation()}
function generate(start){const constrained=hasConstraints(start),data=(constrained?CONSTRAINED:NORMAL).generate(start);BAL.apply(data);data.generator=constrained?'v139-constrained-balanced':'v139-normal-balanced';return data}
function validateSchedule(data){return CONSTRAINED.validateSchedule?.(data)||[]}
window.TM112={generate,validateSchedule};window.TM_FINAL_V139={generate,validateSchedule};document.documentElement.dataset.generatorFinal='v139';
})();