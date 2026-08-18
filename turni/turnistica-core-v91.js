(()=>{
'use strict';
const RESPONSABILI=['Umberto','Fabio','Emanuele'];
const CASSA=['Stefania B','Stefania F','Romina','Giada'];
const SALA=['Giuliano','Manuel','Daniele','Paolo','Marco'];
const JOLLY=[];
const FULL_TIME=new Set(['Umberto','Fabio','Emanuele','Stefania B','Stefania F','Romina','Giuliano','Manuel','Daniele','Paolo']);
const TARGET={Umberto:40,Fabio:40,Emanuele:40,'Stefania B':40,'Stefania F':40,Romina:40,Giada:30,Giuliano:40,Manuel:40,Daniele:40,Paolo:40,Marco:16};
const OFF=new Set(['RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—','']);
const QUICK=['06:30-13:30','06:30-14:30','06:30-15:30','07:00-12:00','07:00-13:00','07:00-14:00','07:00-15:00','07:00-16:00','10:00-15:00','10:00-16:00','10:00-17:00','10:00-18:00','10:00-19:00','11:30-20:30','12:30-20:30','13:30-20:30','14:30-20:30','15:30-20:30','16:00-20:00','16:30-20:30','17:00-20:00','06:30-10:30 / 17:30-20:30','10:00-14:00 / 17:30-20:30','08:00-13:00','RIPOSO','FERIE','PERMESSO','MATERNITÀ','MALATTIA','—'];
function hm(t){const m=String(t||'').trim().match(/^(\d{1,2}):(\d{2})$/);if(!m)return NaN;return +m[1]*60 + +m[2]}
function fmtHm(v){return `${String(Math.floor(v/60)).padStart(2,'0')}:${String(v%60).padStart(2,'0')}`}
function spans(s){if(!s||OFF.has(String(s).trim()))return[];return String(s).split('/').map(p=>p.trim()).map(p=>{const m=p.match(/^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$/);if(!m)return null;const a=hm(m[1]),b=hm(m[2]);return Number.isFinite(a)&&Number.isFinite(b)&&b>a?[a,b]:null}).filter(Boolean)}
function hours(s){return spans(s).reduce((z,[a,b])=>z+(b-a)/60,0)}
function works(s){return spans(s).length>0}
function startsBefore(s,time){const t=hm(time);return spans(s).some(([a])=>a<t)}
function startsAt(s,time){const t=hm(time);return spans(s).some(([a])=>a===t)}
function at(s,time){const t=hm(time);return spans(s).some(([a,b])=>a<=t&&t<b)}
function through(s,time){const t=hm(time);return spans(s).some(([a,b])=>a<=t&&b>=t)}
function weekHours(w,n){return (w.schedule?.[n]||[]).reduce((z,s)=>z+hours(s),0)}
function role(n){if(RESPONSABILI.includes(n))return'Responsabile';if(CASSA.includes(n))return'Cassa';if(SALA.includes(n))return'Sala';if(JOLLY.includes(n))return'Jolly';return''}
function dateLabel(iso){try{return new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(iso+'T12:00:00'))}catch{return iso}}
function isSunday(iso){return new Date(iso+'T12:00:00').getDay()===0}
function issue(type,weekIndex,date,employee,message){return{type,weekIndex,date,employee,message}}
function validateWeek(w,weekIndex=0){
 const out=[];if(!w?.dates||!w?.schedule)return[issue('struttura',weekIndex,null,null,'Settimana non valida')];
 const names=[...RESPONSABILI,...CASSA,...SALA,...JOLLY];
 for(const n of names){const h=weekHours(w,n),t=TARGET[n];if(Math.abs(h-t)>.001)out.push(issue('ore',weekIndex,null,n,`${n}: ${h}h invece di ${t}h`))}
 w.dates.forEach((iso,i)=>{
  const sun=isSunday(iso),lab=dateLabel(iso);
  if(sun){
   const rr=RESPONSABILI.filter(n=>works(w.schedule[n]?.[i]));
   if(rr.length!==1)out.push(issue('responsabili',weekIndex,iso,null,`${lab}: deve lavorare esattamente 1 responsabile la domenica`));
   rr.forEach(n=>{if(w.schedule[n][i]!=='08:00-13:00')out.push(issue('responsabili',weekIndex,iso,n,`${lab}: ${n} deve fare 08:00-13:00`))});
   const cc=CASSA.filter(n=>works(w.schedule[n]?.[i]));
   if(cc.length!==1)out.push(issue('cassa',weekIndex,iso,null,`${lab}: deve lavorare esattamente 1 Cassa la domenica`));
   cc.forEach(n=>{if(w.schedule[n][i]!=='08:00-13:00')out.push(issue('cassa',weekIndex,iso,n,`${lab}: la Cassa domenicale deve fare 08:00-13:00`))});
   const ss=SALA.filter(n=>n!=='Marco'&&works(w.schedule[n]?.[i]));
   if(ss.length!==2)out.push(issue('sala',weekIndex,iso,null,`${lab}: devono lavorare esattamente 2 Sala la domenica`));
   ss.forEach(n=>{if(w.schedule[n][i]!=='08:00-13:00')out.push(issue('sala',weekIndex,iso,n,`${lab}: la Sala domenicale deve fare 08:00-13:00`))});
   if(works(w.schedule.Marco?.[i]))out.push(issue('marco',weekIndex,iso,'Marco',`${lab}: Marco deve riposare la domenica`));
   return;
  }
  const rr=RESPONSABILI.filter(n=>works(w.schedule[n]?.[i]));
  if(rr.length===3){
   const open=rr.filter(n=>startsAt(w.schedule[n][i],'06:30')).length;
   const central=rr.filter(n=>startsAt(w.schedule[n][i],'10:00')).length;
   const close=rr.filter(n=>spans(w.schedule[n][i]).some(([,b])=>b===hm('20:30'))).length;
   if(open!==1||central!==1||close!==1)out.push(issue('responsabili',weekIndex,iso,null,`${lab}: con 3 responsabili servono 1 apertura, 1 centrale e 1 chiusura`));
  }else if(rr.length===2){
   const open=rr.filter(n=>startsAt(w.schedule[n][i],'06:30')).length;
   const close=rr.filter(n=>spans(w.schedule[n][i]).some(([,b])=>b===hm('20:30'))).length;
   if(open!==1||close!==1)out.push(issue('responsabili',weekIndex,iso,null,`${lab}: con un responsabile a riposo servono apertura e chiusura`));
  }else out.push(issue('responsabili',weekIndex,iso,null,`${lab}: numero responsabili al lavoro non valido (${rr.length})`));
  if(!CASSA.some(n=>at(w.schedule[n]?.[i],'07:00')))out.push(issue('cassa',weekIndex,iso,null,`${lab}: manca una Cassa alle 07:00`));
  if(!CASSA.some(n=>through(w.schedule[n]?.[i],'20:30')))out.push(issue('cassa',weekIndex,iso,null,`${lab}: manca una Cassa in chiusura`));
  const early=SALA.filter(n=>startsBefore(w.schedule[n]?.[i],'07:00'));
  if(early.length<2)out.push(issue('sala',weekIndex,iso,null,`${lab}: servono 2 Sala prima delle 07:00`));
  if(!SALA.some(n=>startsAt(w.schedule[n]?.[i],'06:30')))out.push(issue('sala',weekIndex,iso,null,`${lab}: almeno una Sala deve iniziare alle 06:30`));
  if(SALA.filter(n=>at(w.schedule[n]?.[i],'10:00')).length<3)out.push(issue('sala',weekIndex,iso,null,`${lab}: alle 10:00 servono almeno 3 Sala`));
  if(SALA.filter(n=>through(w.schedule[n]?.[i],'20:00')).length<4)out.push(issue('sala',weekIndex,iso,null,`${lab}: servono almeno 4 Sala fino alle 20:00`));
  if(SALA.filter(n=>through(w.schedule[n]?.[i],'20:30')).length<3)out.push(issue('sala',weekIndex,iso,null,`${lab}: servono almeno 3 Sala fino alle 20:30`));
  const d=new Date(iso+'T12:00:00').getDay();
  if(nWorksMarco(w.schedule.Marco?.[i])){
   if(![1,3,4,5,6].includes(d))out.push(issue('marco',weekIndex,iso,'Marco',`${lab}: giorno non consentito per Marco`));
   const h=hours(w.schedule.Marco[i]);if(Math.abs(h-4)>.001)out.push(issue('marco',weekIndex,iso,'Marco',`${lab}: Marco deve fare 4h`));
   const ps=spans(w.schedule.Marco[i]);if(ps[0]&&(ps[0][0]<hm('16:00')||ps[0][0]>hm('16:30')||ps[0][1]<hm('20:00')||ps[0][1]>hm('20:30')))out.push(issue('marco',weekIndex,iso,'Marco',`${lab}: Marco deve stare nel range 16:00/16:30 - 20:00/20:30`));
  }
 });
 for(const n of RESPONSABILI){const sun=w.dates.findIndex(isSunday);if(sun>=0){const sundayWorks=works(w.schedule[n]?.[sun]);const weekdayRests=w.dates.map((d,i)=>({d,i})).filter(x=>!isSunday(x.d)&&w.schedule[n]?.[x.i]==='RIPOSO');if(weekdayRests.length!==1)out.push(issue('riposi',weekIndex,null,n,`${n}: deve avere esattamente 1 RIPOSO infrasettimanale`));if(!sundayWorks&&w.schedule[n]?.[sun]!=='RIPOSO')out.push(issue('riposi',weekIndex,w.dates[sun],n,`${n}: se non lavora domenica deve risultare RIPOSO`))}}
 for(const n of CASSA){const sun=w.dates.findIndex(isSunday);if(sun>=0){const weekdayRests=w.dates.map((d,i)=>({d,i})).filter(x=>!isSunday(x.d)&&w.schedule[n]?.[x.i]==='RIPOSO');if(weekdayRests.length!==1)out.push(issue('riposi',weekIndex,null,n,`${n}: deve avere esattamente 1 RIPOSO infrasettimanale`));if(!works(w.schedule[n]?.[sun])&&w.schedule[n]?.[sun]!=='RIPOSO')out.push(issue('riposi',weekIndex,w.dates[sun],n,`${n}: se non lavora domenica deve risultare RIPOSO`))}}
 for(const n of SALA.filter(n=>n!=='Marco')){const sun=w.dates.findIndex(isSunday);if(sun>=0){const weekdayRests=w.dates.map((d,i)=>({d,i})).filter(x=>!isSunday(x.d)&&w.schedule[n]?.[x.i]==='RIPOSO');if(weekdayRests.length!==1)out.push(issue('riposi',weekIndex,null,n,`${n}: deve avere esattamente 1 RIPOSO infrasettimanale`));if(!works(w.schedule[n]?.[sun])&&w.schedule[n]?.[sun]!=='RIPOSO')out.push(issue('riposi',weekIndex,w.dates[sun],n,`${n}: se non lavora domenica deve risultare RIPOSO`))}}
 return out;
}
function nWorksMarco(s){return works(s)}
function validateSchedule(data){const out=[];(data?.weeks||[]).forEach((w,i)=>out.push(...validateWeek(w,i)));return out}
window.TM91={RESPONSABILI,CASSA,SALA,JOLLY,FULL_TIME,TARGET,OFF,QUICK,hm,fmtHm,spans,hours,works,startsBefore,startsAt,at,through,weekHours,role,dateLabel,isSunday,validateWeek,validateSchedule};
window.validateWeek=w=>validateWeek(w,0).map(x=>x.message);
window.validateScheduleCurrent=data=>validateSchedule(data);
})();