(()=>{
'use strict';
const FLAG='tm_seed_oct1_v80_done',KEY='tm_monthly_manual_overrides_v1',DATE='2026-10-01';
if(localStorage.getItem(FLAG))return;
const wanted={'Stefania B':'13:30-20:30','Emanuele':'13:30-20:30','Paolo':'11:00-20:00','Marco':'16:00-20:30'};
let a=[];try{const x=JSON.parse(localStorage.getItem(KEY)||'[]');if(Array.isArray(x))a=x}catch{}
for(const [employee,shift] of Object.entries(wanted)){a=a.filter(x=>!(x.employee===employee&&x.date===DATE));a.push({employee,date:DATE,shift,updatedAt:new Date().toISOString(),source:'schema richiesto 1 ottobre'})}
localStorage.setItem(KEY,JSON.stringify(a));
try{const d=JSON.parse(localStorage.getItem('tm_planner_draft')||'null'),i=d?.week?.dates?.indexOf(DATE)??-1;if(i>=0){for(const [employee,shift] of Object.entries(wanted))if(d.week.schedule?.[employee])d.week.schedule[employee][i]=shift;localStorage.setItem('tm_planner_draft',JSON.stringify(d))}}catch{}
localStorage.setItem(FLAG,'1');
})();