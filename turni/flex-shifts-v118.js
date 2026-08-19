(()=>{
'use strict';
const C=window.TM91;if(!C)return;

// Turni continui flessibili da preferire nelle settimane con ferie
// prima di aumentare il numero di spezzati.
const FLEX=[
 '07:00-14:30',
 '07:00-16:00',
 '07:00-16:30',
 '07:00-17:00',
 '10:00-17:30',
 '10:00-18:00',
 '10:00-19:00',
 '10:00-19:30',
 '10:00-20:00',
 '11:00-19:00',
 '11:00-20:00',
 '11:30-20:30',
 '12:00-20:30',
 '13:00-20:30'
];

for(const s of FLEX){if(!C.QUICK.includes(s))C.QUICK.push(s)}

window.TM_FLEX_SHIFTS_V118={
 continuous:[...FLEX],
 preferredVacationSplits:[
  '07:00-13:00 / 17:00-20:00',
  '07:00-13:00 / 17:00-20:30'
 ],
 avoidWhenPossible:[
  '06:30-10:30 / 16:30-20:30',
  '06:30-10:30 / 17:30-20:30'
 ],
 responsibleSolo:'06:30-13:30 / 17:00-20:30',
 overtime:{allowedOnVacationWeeks:true,excluded:['Marco'],fairDistribution:true},
 priority:['continuous','fewestSplits','fairOvertime','coverage']
};
})();
