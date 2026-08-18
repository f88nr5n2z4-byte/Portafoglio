(()=>{
'use strict';
const C=window.TM91;if(!C)return;
const baseWeek=C.validateWeek,baseSchedule=C.validateSchedule;
function add(type,weekIndex,date,employee,message){return{type,weekIndex,date,employee,message}}
function roleIndex(pi,d){return(d+pi)%3}
function weekExtra(w,wi){const out=[];
 C.RESPONSABILI.forEach((n,pi)=>{for(let d=0;d<6;d++){const s=w.schedule?.[n]?.[d]||'—',r=roleIndex(pi,d),lab=C.dateLabel(w.dates[d]);if(s==='RIPOSO'){if(r!==2)out.push(add('responsabili',wi,w.dates[d],n,`${lab}: ${n} può riposare solo nel giorno assegnato Centrale`));continue}if(!C.works(s))continue;if(r===0&&!C.startsAt(s,'06:30'))out.push(add('responsabili',wi,w.dates[d],n,`${lab}: ${n} deve essere in Apertura`));if(r===1&&!C.spans(s).some(([,b])=>b===C.hm('20:30')))out.push(add('responsabili',wi,w.dates[d],n,`${lab}: ${n} deve essere in Chiusura`));if(r===2&&!C.startsAt(s,'10:00'))out.push(add('responsabili',wi,w.dates[d],n,`${lab}: ${n} deve essere Centrale`))}});
 for(let d=0;d<6;d++){const n17=C.SALA.filter(n=>C.at(w.schedule?.[n]?.[d],'17:00')).length;if(n17<4)out.push(add('sala',wi,w.dates[d],null,`${C.dateLabel(w.dates[d])}: alle 17:00 devono esserci almeno 4 Sala`))}
 const m=w.schedule?.Marco||[];const required=[0,2,3];required.forEach(d=>{if(!C.works(m[d]))out.push(add('marco',wi,w.dates[d],'Marco',`${C.dateLabel(w.dates[d])}: Marco deve lavorare`))});if(C.works(m[1]))out.push(add('marco',wi,w.dates[1],'Marco',`${C.dateLabel(w.dates[1])}: Marco deve riposare il martedì`));const fs=[4,5].filter(d=>C.works(m[d]));if(fs.length!==1)out.push(add('marco',wi,null,'Marco','Marco deve lavorare esattamente uno tra venerdì e sabato'));if(C.works(m[6]))out.push(add('marco',wi,w.dates[6],'Marco','Marco deve riposare la domenica'));
 return out}
function extendedWeek(w,wi=0){return[...baseWeek(w,wi),...weekExtra(w,wi)]}
function sundayCounts(data,names){const z=Object.fromEntries(names.map(n=>[n,0]));(data?.weeks||[]).forEach(w=>{const i=(w.dates||[]).findIndex(C.isSunday);if(i<0)return;names.forEach(n=>{if(C.works(w.schedule?.[n]?.[i]))z[n]++})});return z}
function fairness(data,names,label,expectedExact=false){const z=sundayCounts(data,names),vals=Object.values(z),out=[];if(expectedExact&&data?.weeks?.length===3){for(const n of names)if(z[n]!==1)out.push(add('rotazione',-1,null,n,`${label}: ${n} deve fare 1 domenica nelle 3 settimane`));return out}if(vals.length&&Math.max(...vals)-Math.min(...vals)>1)out.push(add('rotazione',-1,null,null,`${label}: rotazione domenicale non abbastanza equilibrata`));return out}
function extendedSchedule(data){const out=[];(data?.weeks||[]).forEach((w,i)=>out.push(...extendedWeek(w,i)));out.push(...fairness(data,C.RESPONSABILI,'Responsabili',true));out.push(...fairness(data,C.CASSA,'Cassa'));out.push(...fairness(data,C.SALA.filter(n=>n!=='Marco'),'Sala'));return out}
C.validateWeek=extendedWeek;C.validateSchedule=extendedSchedule;window.validateWeek=w=>extendedWeek(w,0).map(x=>x.message);window.validateScheduleCurrent=data=>extendedSchedule(data);
})();