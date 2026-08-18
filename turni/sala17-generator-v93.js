(()=>{
'use strict';
const KEY='tm_v91_draft';
const FT=['Giuliano','Manuel','Daniele','Paolo'];
const TARGET=40;
function hm(t){const [h,m]=String(t).split(':').map(Number);return h*60+m}
function fmt(v){return `${String(Math.floor(v/60)).padStart(2,'0')}:${String(v%60).padStart(2,'0')}`}
function spans(s){if(!s||['RIPOSO','—','FERIE','PERMESSO','MATERNITÀ','MALATTIA'].includes(s))return[];return String(s).split('/').map(x=>x.trim()).map(x=>{const [a,b]=x.split('-').map(v=>hm(v.trim()));return[a,b]})}
function hours(s){return spans(s).reduce((z,[a,b])=>z+(b-a)/60,0)}
function weekHours(w,n){return(w.schedule?.[n]||[]).reduce((z,s)=>z+hours(s),0)}
function stringify(ps){return ps.map(([a,b])=>`${fmt(a)}-${fmt(b)}`).join(' / ')}
function extendHalf(s){const ps=spans(s).map(x=>[...x]);if(!ps.length||hours(s)>=9-.001)return null;const step=30;if(ps.length>1){if(ps[0][1]+step<=ps[1][0]){ps[0][1]+=step;return stringify(ps)}if(ps[0][0]-step>=hm('06:30')){ps[0][0]-=step;return stringify(ps)}if(ps[1][0]-step>=ps[0][1]){ps[1][0]-=step;return stringify(ps)}}else{if(ps[0][1]+step<=hm('20:30')){ps[0][1]+=step;return stringify(ps)}if(ps[0][0]-step>=hm('06:30')){ps[0][0]-=step;return stringify(ps)}}return null}
function topUp(w,n){let guard=0;while(weekHours(w,n)<TARGET-.001&&guard++<100){let changed=false;for(let d=0;d<6&&weekHours(w,n)<TARGET-.001;d++){const cur=w.schedule[n][d];if(!spans(cur).length)continue;const x=extendHalf(cur);if(x&&weekHours(w,n)+.5<=TARGET+.001){w.schedule[n][d]=x;changed=true}}if(!changed)break}}
function rebuildWeek(w,wi){
 const marcoLate=wi%2===0?4:5,marcoDays=[0,2,3,marcoLate];
 for(let d=0;d<6;d++)w.schedule.Marco[d]=marcoDays.includes(d)?(((d+wi)%2)?'16:30-20:30':'16:00-20:00'):'RIPOSO';w.schedule.Marco[6]='RIPOSO';
 const rest={};marcoDays.forEach((d,j)=>rest[FT[(j+wi)%4]]=d);
 const sundayPairs=[['Giuliano','Paolo'],['Giuliano','Manuel'],['Manuel','Daniele']],sun=sundayPairs[wi%3];
 const E='06:30-10:30 / 17:00-20:30',M='10:00-13:00 / 17:00-20:30',L='17:00-20:00';
 for(let d=0;d<6;d++){
  const active=FT.filter(n=>rest[n]!==d),rot=[...FT.slice((d+wi)%4),...FT.slice(0,(d+wi)%4)].filter(n=>active.includes(n));
  if(marcoDays.includes(d)){rot.forEach((n,j)=>w.schedule[n][d]=j<2?E:M)}else{rot.forEach((n,j)=>w.schedule[n][d]=j<2?E:j===2?M:L)}
  FT.filter(n=>rest[n]===d).forEach(n=>w.schedule[n][d]='RIPOSO');
 }
 FT.forEach(n=>w.schedule[n][6]=sun.includes(n)?'08:00-13:00':'RIPOSO');
 FT.forEach(n=>topUp(w,n));
}
function patchGenerated(){try{const data=JSON.parse(localStorage.getItem(KEY)||'null');if(!data?.weeks?.length)return;data.weeks.forEach(rebuildWeek);data.generator='v93';localStorage.setItem(KEY,JSON.stringify(data));sessionStorage.setItem('tm_v93_sala17_done','1');location.reload()}catch(e){console.error('sala17 v93',e)}}
document.addEventListener('click',e=>{if(e.target.closest('.v91gen'))setTimeout(patchGenerated,100)});
})();