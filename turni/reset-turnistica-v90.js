(()=>{
'use strict';
const key='tm_full_turnistica_reset_v90';
if(!localStorage.getItem(key)){
 ['tm_planner_draft','tm_monthly_absences_v1','tm_monthly_manual_overrides_v1','tm_monthly_auto_fixes_v1','tm_monthly_balance_v1','tm_monthly_coverage_v1','tm_monthly_streak_v1'].forEach(k=>localStorage.removeItem(k));
 localStorage.setItem(key,'1');
}
window.validateWeek=()=>[];
window.validateWeekAdvice=()=>[];
window.validateScheduleCurrent=()=>[];
window.TM_RULES_RESET=true;
})();
