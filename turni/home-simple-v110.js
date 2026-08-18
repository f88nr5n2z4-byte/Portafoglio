(()=>{
'use strict';
try{
 if(typeof adminHome==='function'&&typeof adminSchedule==='function')adminHome=function(w){return adminSchedule(w)};
 if(typeof employeeHome==='function'&&typeof employeeSchedule==='function')employeeHome=function(u,w){return employeeSchedule(w,u.employee)};
}catch(e){console.warn('home simple',e)}
})();