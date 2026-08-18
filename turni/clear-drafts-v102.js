(()=>{
'use strict';
const MARK='tm_drafts_cleared_v102';
try{
 if(localStorage.getItem(MARK))return;
 localStorage.removeItem('tm_v91_draft');
 localStorage.removeItem('tm_planner_draft');
 sessionStorage.removeItem('tm_staff_equity_v100');
 sessionStorage.removeItem('tm_staff_equity_v101');
 localStorage.setItem(MARK,'1');
 console.info('Bozze turni precedenti cancellate (v102)');
}catch(e){console.warn('Pulizia bozze v102',e)}
})();