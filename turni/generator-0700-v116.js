(()=>{
'use strict';
const C=window.TM91,BASE=window.TM112;if(!C||!BASE)return;
const RESP=[...C.RESPONSABILI],CASH=[...C.CASSA],FLOOR=['Giuliano','Manuel','Daniele','Paolo'];
const ALL=[...RESP,...CASH,...C.SALA];
const ALT={
 '07:00-15:00':'09:00-17:00',
 '07:00-14:00':'10:00-17:00',
 '07:00-13:00':'11:00-17:00',
 '07:00-12:00':'12:00-17:00',
 '07:00-11:00 / 16:30-20:30':'10:00-14:00 / 16:30-20:30',
 '07:00-11:00 / 17:30-20:30':'10:00-13:30 / 17:00-20:30',
 '07:00-10:00 / 17:30-20:30':'10:00-13:00 / 17:00-20:00',
 '07:00-09:00 / 17:30-20:30':'10:00-12:00 / 17:30-20:30',
 '06:30-14:30':'09:00-17:00',
 '06:30-13:30':'10:00-17:00',
 '06:30-10:30 / 16:30-20:30':'10:00-14:00 / 16:30-20:30',
 '06:30-10:30 / 17:30-20:30':'10:00-13:30 / 17:00-20:30'
};
const at=(w,n,d,t)=>C.at(w.schedule?.[n]?.[d],t);
const count=(w,d,t)=>ALL.reduce((z,n)=>z+(at(w,n,d,t)?1:0),0);
const roleOk=(w,d)=>RESP.some(n=>at(w,n,d,'06:45'))&&FLOOR.some(n=>at(w,n,d,'06:45'))&&CASH.some(n=>at(w,n,d,'07:00'));
function tryReduce(data,wi,d){
 const w=data.weeks[wi];
 const people=ALL.filter(n=>at(w,n,d,'07:00')&&ALT[w.schedule?.[n]?.[d]]);
 // Prima sposta una presenza duplicata di Sala/Cassa; il Responsabile di apertura è l'ultima scelta.
 people.sort((a,b)=>(RESP.includes(a)?2:CASH.includes(a)?1:0)-(RESP.includes(b)?2:CASH.includes(b)?1:0));
 for(const n of people){
  const old=w.schedule[n][d],next=ALT[old];
  w.schedule[n][d]=next;
  const ok=count(w,d,'07:00')>=4&&roleOk(w,d)&&BASE.validateSchedule(data).length===0;
  if(ok)return true;
  w.schedule[n][d]=old;
 }
 return false;
}
function normalize(data){
 for(let wi=0;wi<(data?.weeks||[]).length;wi++){
  const w=data.weeks[wi];
  for(let d=0;d<Math.min(6,w.dates?.length||0);d++){
   let guard=0;
   while(count(w,d,'07:00')>4&&guard++<8){
    if(!tryReduce(data,wi,d))throw new Error(`${C.dateLabel(w.dates[d])}: impossibile ridurre a 4 le persone attive alle 07:00 senza violare le altre regole`);
   }
  }
 }
 return data;
}
function exactErrors(data){
 const out=[];
 (data?.weeks||[]).forEach((w,wi)=>{
  for(let d=0;d<Math.min(6,w.dates?.length||0);d++){
   const n=count(w,d,'07:00');
   if(n!==4)out.push({type:'copertura',weekIndex:wi,date:w.dates[d],employee:null,message:`${C.dateLabel(w.dates[d])}: alle 07:00 devono esserci esattamente 4 persone totali (ora ${n})`});
  }
 });
 return out;
}
function generate(start){return normalize(BASE.generate(start))}
function validateSchedule(data){return[...BASE.validateSchedule(data),...exactErrors(data)]}
C.validateSchedule=validateSchedule;
C.validateWeek=(w,wi=0)=>validateSchedule({weeks:[w]}).map(x=>({...x,weekIndex:wi}));
window.validateScheduleCurrent=validateSchedule;
window.validateWeek=w=>C.validateWeek(w,0).map(x=>x.message);
window.TM112={generate,validateSchedule};
window.TM116={generate,validateSchedule};
})();
