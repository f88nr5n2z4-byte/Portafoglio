(()=>{
'use strict';
const PREV=window.TM112;if(!PREV)return;
const KEY='tm_v125_requests',MONTHS={gen:0,feb:1,mar:2,apr:3,mag:4,giu:5,lug:6,ago:7,set:8,ott:9,nov:10,dic:11};
const iso=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
function reqDate(x){const g=String(x?.message||'').match(/Giorno:\s*([^\n]+)/);if(!g)return null;const m=g[1].toLowerCase().match(/(?:lun|mar|mer|gio|ven|sab|dom)?\s*(\d{1,2})\s+([a-zà]+)/i);if(!m)return null;const mon=MONTHS[m[2].slice(0,3)];if(mon===undefined)return null;const b=x.created_at?new Date(x.created_at):new Date(),ys=[b.getFullYear()-1,b.getFullYear(),b.getFullYear()+1];let best=null,z=Infinity;for(const y of ys){const d=new Date(y,mon,+m[1],12),q=Math.abs(d-b);if(q<z){best=d;z=q}}return best?iso(best):null}
function range(start){const m=new Date(start+'T12:00:00'),k=(m.getDay()+6)%7;m.setDate(m.getDate()-k);const e=new Date(m);e.setDate(m.getDate()+20);return[iso(m),iso(e)]}
function generate(start){let raw=null,list=[];try{raw=localStorage.getItem(KEY);list=JSON.parse(raw||'[]');if(!Array.isArray(list))list=[]}catch{list=[]}const [from,to]=range(start),filtered=list.filter(x=>{if(x?.status!=='ACCETTATA')return true;const d=reqDate(x);return !d||(d>=from&&d<=to)});try{localStorage.setItem(KEY,JSON.stringify(filtered));return PREV.generate(start)}finally{if(raw===null)localStorage.removeItem(KEY);else localStorage.setItem(KEY,raw)}}
window.TM112={generate,validateSchedule:PREV.validateSchedule};document.documentElement.dataset.requestRange='v137';
})();