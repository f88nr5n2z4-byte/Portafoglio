// Regole turnazione aggiornate: centrale = turno continuativo che parte dentro la fascia mattina (dopo le 07:00 e prima delle 13:30) e termina dopo le 14:30.
// Il ruolo non conta: anche una cassiera può essere il centrale se l'orario rispetta questa regola.
function isCentralShift(s){
  if(!s||ABSENCES.has(s))return false;
  const ps=spans(s);
  if(ps.length!==1)return false;
  const [start,end]=ps[0];
  return start>hm('07:00')&&start<hm('13:30')&&end>hm('14:30');
}

validateWeek=function(w){
  const issues=[];
  const aft=weekAfternoonGroup(w);
  w.dates.forEach((iso,i)=>{
    const day=new Date(iso+'T12:00:00').getDay();
    const active=Object.entries(w.schedule).filter(([,a])=>a[i]&&!ABSENCES.has(a[i]));
    if(day===0){
      if(active.length!==4)issues.push(`${fmtDate(iso)}: domenica ${active.length} persone invece di 4`);
      if(aft){
        const wrong=active.map(([n])=>n).filter(n=>!aft.includes(n));
        if(wrong.length)issues.push(`${fmtDate(iso)}: domenica lavorano persone del turno sbagliato (${wrong.join(', ')})`);
      }
      return;
    }
    const at630=active.filter(([,a])=>starts(a[i],'06:30')).length;
    const at7=active.filter(([,a])=>present(a[i],'07:00')).length;
    const at11=active.filter(([,a])=>present(a[i],'11:00')).length;
    const close=active.filter(([,a])=>present(a[i],'20:29')).length;
    const cash=active.filter(([n,a])=>CASH.has(n)&&present(a[i],'13:30')).length;
    const r1=active.filter(([n,a])=>RESP.has(n)&&starts(a[i],'06:30')).length;
    const r2=active.filter(([n,a])=>RESP.has(n)&&present(a[i],'17:00')&&present(a[i],'20:29')).length;
    const central=active.filter(([,a])=>isCentralShift(a[i])).length;

    if(at630<2)issues.push(`${fmtDate(iso)}: solo ${at630} alle 06:30`);
    if(at7<4)issues.push(`${fmtDate(iso)}: solo ${at7} alle 07:00`);
    if(close!==4)issues.push(`${fmtDate(iso)}: ${close} in chiusura invece di 4`);
    if(!cash)issues.push(`${fmtDate(iso)}: manca cassa alle 13:30`);
    if(!r1)issues.push(`${fmtDate(iso)}: manca responsabile mattina`);
    if(!r2)issues.push(`${fmtDate(iso)}: manca responsabile pomeriggio/chiusura`);
    if([1,3,4].includes(day)){
      if(at11<5)issues.push(`${fmtDate(iso)}: meno di 5 alle 11`);
      if(central!==1)issues.push(`${fmtDate(iso)}: centrali = ${central} invece di 1`);
    }
    if(day===6){
      const rests=Object.entries(w.schedule).filter(([,a])=>a[i]==='RIPOSO').map(([n])=>n);
      if(rests.length)issues.push(`${fmtDate(iso)}: riposo sabato ${rests.join(', ')}`);
    }
  });
  if(aft){
    for(const n of aft){
      const arr=w.schedule[n]||[];
      const fullyAway=arr.every(s=>['FERIE','PERMESSO','MATERNITÀ','MALATTIA','—'].includes(s));
      if(!fullyAway&&!arr.includes('RIPOSO'))issues.push(`${n}: manca il riposo settimanale del turno pomeriggio`);
    }
  }
  if(w.schedule.Marco){
    const h=weekHours(w,'Marco');
    if(w.dates.length===7&&h!==16)issues.push(`Marco: ${h}h invece di 16h`);
  }
  return issues;
};