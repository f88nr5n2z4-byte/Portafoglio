(()=>{
'use strict';
function publishedWeek(date){return (schedule.weeks||[]).find(w=>(w.dates||[]).includes(date))||null}
function hasOtherRest(w,date){if(!w)return false;const di=w.dates.indexOf(date),arr=w.schedule?.[u.display]||[];return arr.some((s,i)=>i!==di&&String(s).toUpperCase()==='RIPOSO')}
send=async function(){
 if(!selectedDate)return alert('Scegli prima il giorno.');
 let wanted=type;
 const pw=publishedWeek(selectedDate);
 if(type==='RIPOSO'&&pw&&hasOtherRest(pw,selectedDate)&&new Date(selectedDate+'T12:00:00').getDay()!==0)wanted='PERMESSO';
 if(type==='TURNO'){
  wanted=document.getElementById('quick').value;const a=document.getElementById('s1').value,b=document.getElementById('e1').value,c=document.getElementById('s2').value,z=document.getElementById('e2').value;
  if(a||b||c||z){if(!a||!b||hm(b)<=hm(a))return alert('Controlla la prima fascia.');wanted=`${a}-${b}`;if(c||z){if(!c||!z||hm(z)<=hm(c)||hm(c)<hm(b))return alert('Controlla la seconda fascia.');wanted+=` / ${c}-${z}`}}
 }
 const label=new Intl.DateTimeFormat('it-IT',{weekday:'short',day:'numeric',month:'short'}).format(new Date(selectedDate+'T12:00:00')),cur=currentShift(selectedDate),title=wanted==='RIPOSO'?'RICHIESTA RIPOSO':wanted==='FERIE'?'RICHIESTA FERIE':wanted==='PERMESSO'?'RICHIESTA PERMESSO':'RICHIESTA CAMBIO TURNO',msg=`${title}\nGiorno: ${label}\nTurno attuale: ${cur}\nTurno richiesto: ${wanted}`,btn=document.getElementById('send');
 btn.disabled=true;try{await api('create_request',{method:'POST',body:{message:msg}});document.getElementById('result').innerHTML=`<div class="success" style="margin-top:10px">${wanted==='PERMESSO'&&type==='RIPOSO'?'Hai già un riposo in settimana: richiesta inviata come PERMESSO.':'Richiesta inviata a Eurospin.'}</div>`}catch(e){document.getElementById('result').innerHTML=`<div class="error" style="margin-top:10px">${esc(e.message)}</div>`;btn.disabled=false}
};
})();