(()=>{
'use strict';
const prevApi=api;
const PROTECTED=new Set(['FERIE','MALATTIA','MATERNITÀ','PERMESSO']);
const ALLOWED=new Set(['15:30-19:30','16:00-20:00','16:30-20:30']);
function stateMonth(){try{const w=JSON.parse(localStorage.getItem('tm_planner_draft')||'null')?.week;if(w?.dates?.length)return new Date(w.dates[Math.floor(w.dates.length/2)]+'T12:00:00')}catch{}return new Date()}
function iso(d){return d.toLocaleDateString('sv-SE')}
function fmt(d){return new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(d+'T12:00:00'))}
function isoWeek(d){const x=new Date(Date.UTC(d.getFullYear(),d.getMonth(),d.getDate()));const day=x.getUTCDay()||7;x.setUTCDate(x.getUTCDate()+4-day);const y0=new Date(Date.UTC(x.getUTCFullYear(),0,1));return Math.ceil((((x-y0)/86400000)+1)/7)}
function marcoShift(d){const day=d.getDay();if(day===1||day===3||day===4)return'16:00-20:00';const wk=isoWeek(d);if(day===5&&wk%2===1)return'16:00-20:00';if(day===6&&wk%2===0)return'16:00-20:00';return'RIPOSO'}
function parsed(x){if(x?.employee!=='Marco'||x.status!=='ACCETTATA')return null;const g=String(x.message||'').match(/Giorno:\s*([^\n]+).*?Turno richiesto:\s*([^\n]+)/s);return g?{label:g[1].trim(),wanted:g[2].trim(),id:String(x.id||'')}:null}
function keepExisting(base,label){for(const x of base){const p=parsed(x);if(!p||p.label!==label)continue;if(PROTECTED.has(p.wanted))return true;if(p.id.startsWith('override-')&&ALLOWED.has(p.wanted))return true}return false}
function synthetic(base){const center=stateMonth(),from=new Date(center.getFullYear(),center.getMonth()-2,1,12),to=new Date(center.getFullYear(),center.getMonth()+3,0,12),out=[];for(let d=new Date(from);d<=to;d.setDate(d.getDate()+1)){const date=iso(d),label=fmt(date);if(keepExisting(base,label))continue;out.push({id:`marco-rule-${date}`,employee:'Marco',status:'ACCETTATA',replied_at:new Date().toISOString(),message:`Giorno: ${label}\nTurno richiesto: ${marcoShift(new Date(date+'T12:00:00'))}\nOrigine: regola fissa Marco`})}return out}
api=async function(action,opts={}){const r=await prevApi(action,opts);if(action!=='list_requests')return r;const base=Array.isArray(r.requests)?r.requests:[];return{...r,requests:[...base,...synthetic(base)]}}
})();