(()=>{
'use strict';
const PREV=window.TM112,BAL=window.TM_BALANCED_V138;if(!PREV||!BAL)return;
const REQ='tm_v125_requests',ABS='tm_v125_absences';
const MONTHS={gen:0,feb:1,mar:2,apr:3,mag:4,giu:5,lug:6,ago:7,set:8,ott:9,nov:10,dic:11};
const iso=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
function monday(start){const d=new Date(start+'T12:00:00'),k=(d.getDay()+6)%7;d.setDate(d.getDate()-k);return d}
function range(start){const a=monday(start),b=new Date(a);b.setDate(a.getDate()+20);return[iso(a),iso(b)]}
function parseReqDate(x){const g=String(x?.message||'').match(/Giorno:\s*([^\n]+)/);if(!g)return null;const m=g[1].toLowerCase().match(/(?:lun|mar|mer|gio|ven|sab|dom)?\s*(\d{1,2})\s+([a-zà]+)/i);if(!m)return null;const mon=MONTHS[m[2].slice(0,3)];if(mon===undefined)return null;const base=x.created_at?new Date(x.created_at):new Date(),ys=[base.getFullYear()-1,base.getFullYear(),base.getFullYear()+1];let best=null,z=Infinity;for(const y of ys){const d=new Date(y,mon,+m[1],12),q=Math.abs(d-base);if(q<z){best=d;z=q}}return best?iso(best):null}
function load(k){try{const x=JSON.parse(localStorage.getItem(k)||'[]');return Array.isArray(x)?x:[]}catch{return[]}}
function hasConstraints(start){const[from,to]=range(start);const req=load(REQ).some(x=>x?.status==='ACCETTATA'&&(()=>{const d=parseReqDate(x);return d&&d>=from&&d<=to})());const abs=load(ABS).some(x=>x?.from&&x?.to&&x.to>=from&&x.from<=to);return req||abs}
function generate(start){if(hasConstraints(start))return PREV.generate(start);const oldR=localStorage.getItem(REQ),oldA=localStorage.getItem(ABS);try{localStorage.setItem(REQ,'[]');localStorage.setItem(ABS,'[]');const out=BAL.generate(start);out.generator='v138-normal-router';return out}finally{if(oldR===null)localStorage.removeItem(REQ);else localStorage.setItem(REQ,oldR);if(oldA===null)localStorage.removeItem(ABS);else localStorage.setItem(ABS,oldA)}}
window.TM112={generate,validateSchedule:PREV.validateSchedule};document.documentElement.dataset.generatorRouter='v138';
})();