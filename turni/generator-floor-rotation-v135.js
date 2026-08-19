(()=>{
'use strict';
const PREV=window.TM112,C=window.TM91;
if(!PREV||!C)return;
const FLOOR=['Giuliano','Manuel','Daniele','Paolo'];
const CASH=['Stefania B','Stefania F','Romina','Giada'];
const GROUPS=[FLOOR,CASH];
const roleOf=(s,group)=>{
 if(!C.works(s))return'off';
 if(C.spans(s).length>1)return'split';
 if(group===CASH){
  if(C.at(s,'07:00'))return'open';
  if(C.at(s,'20:29'))return'close';
  return'mid';
 }
 if(C.at(s,'06:45'))return'open';
 if(C.at(s,'20:29'))return'close';
 return'mid';
};
const locked=(data,n,date)=>{
 const req=data?.constraints?.acceptedRequests||[];
 if(req.some(x=>x.employee===n&&x.date===date))return true;
 const abs=data?.constraints?.absences||[];
 return abs.some(x=>x.employee===n&&date>=x.from&&date<=x.to);
};
function perms(a){
 if(a.length<2)return[a.slice()];
 const out=[];
 const rec=(left,cur)=>{if(!left.length){out.push(cur.slice());return}for(let i=0;i<left.length;i++)rec([...left.slice(0,i),...left.slice(i+1)],[...cur,left[i]])};
 rec(a,[]);return out;
}
function scoreAssign(names,shifts,hist,group){
 let max=0,sum=0,repeat=0;
 names.forEach((n,i)=>{
  const r=roleOf(shifts[i],group),h=hist[n]||{},v=(h[r]||0)+1;
  max=Math.max(max,v);sum+=v*v;
  if(h.last===r)repeat++;
 });
 return[max,repeat,sum];
}
function lex(a,b){for(let i=0;i<a.length;i++){if(a[i]!==b[i])return a[i]-b[i]}return 0}
function rotateGroup(data,group,hist,w,d){
 const date=w.dates[d];
 const eligible=group.filter(n=>C.works(w.schedule?.[n]?.[d])&&!locked(data,n,date));
 const byHours={};
 eligible.forEach(n=>{const h=C.hours(w.schedule[n][d]).toFixed(2);(byHours[h]||(byHours[h]=[])).push(n)});
 Object.values(byHours).forEach(names=>{
  if(names.length<2)return;
  const original=names.map(n=>w.schedule[n][d]);
  let best=original,bestScore=scoreAssign(names,original,hist,group);
  for(const p of perms(original)){
   const sc=scoreAssign(names,p,hist,group);
   if(lex(sc,bestScore)<0){best=p;bestScore=sc}
  }
  names.forEach((n,i)=>w.schedule[n][d]=best[i]);
 });
 group.forEach(n=>{
  const s=w.schedule?.[n]?.[d];if(!C.works(s))return;
  const r=roleOf(s,group);hist[n][r]=(hist[n][r]||0)+1;hist[n].last=r;
 });
}
function rotate(data){
 const histories={};
 GROUPS.flat().forEach(n=>histories[n]={open:0,mid:0,close:0,split:0,last:null});
 for(const w of data?.weeks||[]){
  for(let d=0;d<6;d++){
   rotateGroup(data,FLOOR,histories,w,d);
   rotateGroup(data,CASH,histories,w,d);
  }
 }
 data.floorRotation='v136-balanced';
 data.cashRotation='v136-balanced';
 return data;
}
function generate(start){return rotate(PREV.generate(start))}
function validateSchedule(data){return PREV.validateSchedule(data)}
window.TM112={generate,validateSchedule};
window.TM136={generate,validateSchedule};
document.documentElement.dataset.floorRotation='v136';
document.documentElement.dataset.cashRotation='v136';
})();