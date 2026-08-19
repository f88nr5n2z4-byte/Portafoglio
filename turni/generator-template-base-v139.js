(()=>{
'use strict';
const NORMAL=window.TM112;if(!NORMAL)return;
const REQ='tm_v125_requests',ABS='tm_v125_absences',ROT='tm_rotation_v125';
function restore(k,v){if(v===null)localStorage.removeItem(k);else localStorage.setItem(k,v)}
function generate(start){const r=localStorage.getItem(REQ),a=localStorage.getItem(ABS),o=localStorage.getItem(ROT);try{localStorage.setItem(REQ,'[]');localStorage.setItem(ABS,'[]');localStorage.setItem(ROT,'{}');const data=NORMAL.generate(start);data.generator='v139-template-base';data.constraints={acceptedRequests:[],absences:[]};return data}finally{restore(REQ,r);restore(ABS,a);restore(ROT,o)}}
const API={generate,validateSchedule:NORMAL.validateSchedule};
window.TM_NORMAL_V139=NORMAL;
window.TM_TEMPLATE_BASE_V139=API;
window.TM112=API;
document.documentElement.dataset.templateBase='v139';
})();