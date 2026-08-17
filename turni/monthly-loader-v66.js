(()=>{
'use strict';
const box=document.getElementById('app');
const fail=e=>{console.error(e);if(box)box.innerHTML=`<div class="error" style="margin:20px"><b>Errore Nuovi Turni</b><br>${typeof esc==='function'?esc(e?.message||e):String(e?.message||e)}</div>`};
(async()=>{
 try{
  const r=await fetch('monthly-turns-v62.js?v=67',{cache:'no-store'});if(!r.ok)throw new Error(`Motore mensile non caricato (${r.status})`);let c=await r.text();
  const old="function build(y,m){const w=blank(y,m);applyAccepted(w);for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)assignSunday(w,i);else{assignResp(w,i);assignOps(w,i)}}return w}";
  if(!c.includes(old))throw new Error('Motore mensile non compatibile con la riparazione automatica v67');
  const repair=`
function repairDaySnapshot(w,i){const s={};for(const n of N)s[n]=w.schedule[n][i];return s}
function repairRestoreDay(w,i,s){for(const n of N)w.schedule[n][i]=s[n]}
function repairHardCount(w,i){
 const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)return 0;let z=0;
 const rw=R.filter(n=>works(w.schedule[n][i]));
 if(rw.length===3){for(const s of ['06:30-13:30','10:00-17:00','13:30-20:30'])if(!rw.some(n=>w.schedule[n][i]===s))z++}
 else if(rw.length===2){if(!rw.some(n=>w.schedule[n][i]==='06:30-13:30'))z++;if(!rw.some(n=>w.schedule[n][i]==='13:30-20:30'))z++}
 else if(rw.length===1){const s=w.schedule[rw[0]][i];if(!startsAt(s,'06:30')||!at(s,'20:29'))z++}else z+=2;
 const mc=roleMorningCash(w,i);if(!mc||!cashCovered(w,i,'07:00','13:30'))z++;
 const sala=N.filter(n=>at(w.schedule[n][i],'07:00')&&S.includes(n)&&n!==mc);if(sala.length<2)z++;if(!sala.some(n=>startsAt(w.schedule[n][i],'06:30')))z++;
 if(N.filter(n=>at(w.schedule[n][i],'07:00')).length<4)z++;
 if(!cashCovered(w,i,'13:30','20:30'))z++;
 return z;
}
function repairPick(w,list,i,exclude=new Set()){
 return list.filter(n=>!exclude.has(n)&&!locked.has(n+'|'+i)&&!PROT.has(w.schedule[n][i])&&w.schedule[n][i]!=='RIPOSO').sort((a,b)=>{const aw=works(w.schedule[a][i])?0:1,bw=works(w.schedule[b][i])?0:1;return aw-bw||N.indexOf(a)-N.indexOf(b)})[0]||null;
}
function repairResponsibleDay(w,i){
 const unavailable=R.filter(n=>w.schedule[n][i]==='RIPOSO'||PROT.has(w.schedule[n][i])),available=R.filter(n=>!unavailable.includes(n));
 if(available.length===2){const a=available[0],b=available[1];if(!locked.has(a+'|'+i))w.schedule[a][i]='06:30-13:30';if(!locked.has(b+'|'+i))w.schedule[b][i]='13:30-20:30'}
 else if(available.length===3){const shifts=['06:30-13:30','10:00-17:00','13:30-20:30'];for(let k=0;k<3;k++)if(!locked.has(available[k]+'|'+i))w.schedule[available[k]][i]=shifts[k]}
 else if(available.length===1&&!locked.has(available[0]+'|'+i))w.schedule[available[0]][i]='06:30-13:30 / 17:00-20:30';
}
function repairCoverage(w,i){
 const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0)return;repairResponsibleDay(w,i);
 let mc=roleMorningCash(w,i);
 if(!mc||!cashCovered(w,i,'07:00','13:30')){const n=repairPick(w,[...C,...CB],i);if(n)w.schedule[n][i]='07:00-14:00'}
 mc=roleMorningCash(w,i);let sala=N.filter(n=>at(w.schedule[n][i],'07:00')&&S.includes(n)&&n!==mc);
 if(!sala.some(n=>startsAt(w.schedule[n][i],'06:30'))){const n=repairPick(w,S.filter(x=>x!=='Marco'&&x!==mc),i,new Set(sala));if(n)w.schedule[n][i]='06:30-13:30'}
 mc=roleMorningCash(w,i);sala=N.filter(n=>at(w.schedule[n][i],'07:00')&&S.includes(n)&&n!==mc);
 while(sala.length<2){const n=repairPick(w,S.filter(x=>x!=='Marco'&&x!==mc),i,new Set(sala));if(!n)break;w.schedule[n][i]='07:00-14:00';sala.push(n)}
 if(!cashCovered(w,i,'13:30','20:30')){const n=repairPick(w,[...C,...CB],i);if(n)w.schedule[n][i]='13:30-20:30'}
 let closers=O.filter(n=>at(w.schedule[n][i],'20:29')).length;
 while(closers<3){const used=new Set(O.filter(n=>at(w.schedule[n][i],'20:29'))),n=repairPick(w,O,i,used);if(!n)break;w.schedule[n][i]='13:30-20:30';closers++}
 const dow=d.getDay(),need=[1,3,4].includes(dow)?5:4,end=[1,3,4].includes(dow)?'16:30':'17:00';
 let guard=0;while(intervalMin(w,i,'13:30',end)<need&&guard++<12){const used=new Set(N.filter(x=>at(w.schedule[x][i],'13:30'))),n=repairPick(w,O,i,used);if(!n)break;w.schedule[n][i]='10:00-17:00'}
 guard=0;while(N.filter(n=>at(w.schedule[n][i],'11:00')).length<5&&guard++<12){const used=new Set(N.filter(x=>at(w.schedule[x][i],'11:00'))),n=repairPick(w,O,i,used);if(!n)break;w.schedule[n][i]='10:00-17:00'}
}
function repairFirstStreakViolation(w){
 for(const n of N){let streak=previousStreak(n,w);for(let i=0;i<w.dates.length;i++){if(works(w.schedule[n][i])){streak++;if(streak>6)return{n,i}}else streak=0}}return null;
}
function repairInsertRest(w,n,vi){
 const start=Math.max(0,vi-5),cand=[];
 for(let j=start;j<=vi;j++){const d=new Date(w.dates[j]+'T12:00:00');if(d.getDay()===0||locked.has(n+'|'+j)||!works(w.schedule[n][j]))continue;if(R.includes(n)&&R.filter(x=>works(w.schedule[x][j])).length<3)continue;
  const snap=repairDaySnapshot(w,j),before=repairHardCount(w,j);w.schedule[n][j]='RIPOSO';repairCoverage(w,j);const after=repairHardCount(w,j);repairRestoreDay(w,j,snap);cand.push({j,score:(after-before)*100+(j===vi?5:0)})}
 if(!cand.length)return false;cand.sort((a,b)=>a.score-b.score||a.j-b.j);const j=cand[0].j;w.schedule[n][j]='RIPOSO';repairCoverage(w,j);return true;
}
function repairSundayRests(w){
 let changed=false;for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()!==0)continue;const key=monday(w.dates[i]);for(const n of N.filter(n=>works(w.schedule[n][i]))){let rest=false;for(let k=0;k<w.dates.length;k++)if(monday(w.dates[k])===key&&w.schedule[n][k]==='RIPOSO')rest=true;if(rest)continue;
   const cand=[];for(let k=Math.max(0,i-6);k<i;k++){if(monday(w.dates[k])!==key||locked.has(n+'|'+k)||!works(w.schedule[n][k]))continue;if(R.includes(n)&&R.filter(x=>works(w.schedule[x][k])).length<3)continue;const snap=repairDaySnapshot(w,k),before=repairHardCount(w,k);w.schedule[n][k]='RIPOSO';repairCoverage(w,k);const after=repairHardCount(w,k);repairRestoreDay(w,k,snap);cand.push({k,score:after-before})}
   if(cand.length){cand.sort((a,b)=>a.score-b.score||a.k-b.k);const k=cand[0].k;w.schedule[n][k]='RIPOSO';repairCoverage(w,k);changed=true}
  }}return changed;
}
function repairMonthHours(w,n){return Math.round((w.schedule[n]||[]).reduce((z,s)=>z+hrs(s),0)*100)/100}
function repairProtectedMonth(w,n){return (w.schedule[n]||[]).some(s=>PROT.has(s))}
function repairLongerOptions(s){
 const map={
  '06:30-13:30':['06:30-14:30','06:30-15:00'],
  '07:00-14:00':['07:00-15:00','07:00-16:00'],
  '07:00-13:00':['07:00-14:00','07:00-15:00'],
  '08:00-13:00':['08:00-16:00','08:00-17:00'],
  '09:00-12:00':['09:00-17:00'],
  '09:00-14:00':['09:00-17:00','09:00-18:00'],
  '10:00-16:00':['10:00-17:00','10:00-18:00'],
  '10:00-17:00':['10:00-18:00','10:00-19:00'],
  '11:00-18:00':['11:00-19:00','11:00-20:00'],
  '13:30-20:30':['12:30-20:30','12:00-20:30'],
  '14:00-20:00':['12:30-20:00','12:00-20:00'],
  '14:00-20:30':['12:30-20:30','12:00-20:30'],
  '16:00-20:00':['12:30-20:30'],
  '16:30-20:30':['12:30-20:30']
 };return map[s]||[];
}
function repairMonthlyHours(w){
 const full=O.filter(n=>n!=='Giada'&&n!=='Marco');
 for(const n of full){if(repairProtectedMonth(w,n))continue;let h=repairMonthHours(w,n),guard=0;
  while(h<172&&guard++<80){let best=null;for(let i=0;i<w.dates.length;i++){const d=new Date(w.dates[i]+'T12:00:00');if(d.getDay()===0||locked.has(n+'|'+i)||!works(w.schedule[n][i]))continue;const old=w.schedule[n][i];for(const s of repairLongerOptions(old)){const gain=hrs(s)-hrs(old);if(gain<=0)continue;const over=Math.max(0,h+gain-173),score=over*100+Math.abs(172-(h+gain));if(!best||score<best.score)best={i,s,gain,score}}
   }if(!best)break;w.schedule[n][best.i]=best.s;h=repairMonthHours(w,n)}
 }
 return w;
}
function repairMonth(w){
 for(let pass=0;pass<10;pass++){
  let changed=repairSundayRests(w),guard=0,v;
  while((v=repairFirstStreakViolation(w))&&guard++<120){if(!repairInsertRest(w,v.n,v.i))break;changed=true}
  for(let i=0;i<w.dates.length;i++)if(new Date(w.dates[i]+'T12:00:00').getDay()!==0&&repairHardCount(w,i)>0)repairCoverage(w,i);
  if(!changed&&!repairFirstStreakViolation(w))break;
 }
 repairMonthlyHours(w);
 for(let i=0;i<w.dates.length;i++)if(new Date(w.dates[i]+'T12:00:00').getDay()!==0&&repairHardCount(w,i)>0)repairCoverage(w,i);
 return w;
}
`;
  const neu=repair+old.replace('return w}','return repairMonth(w)}');c=c.replace(old,neu);
  new Function('"use strict";\n'+c)();
 }catch(e){fail(e)}
})();
})();