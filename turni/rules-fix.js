// Regole complete Eurospin Torre Maura.
// Centrale: turno CONTINUO che parte dopo le 07:00 e prima delle 13:30 e termina dopo le 14:30.
// Il ruolo non conta: anche cassa/sala/responsabile può essere centrale se l'orario rispetta la definizione.
function isCentralShift(s){
  if(!s||ABSENCES.has(s))return false;
  const ps=spans(s);
  if(ps.length!==1)return false;
  const [start,end]=ps[0];
  return start>hm('07:00')&&start<hm('13:30')&&end>hm('14:30');
}

function previousWeekForRules(w){
  try{
    let weeks=[];
    if(typeof official!=='undefined'&&Array.isArray(official?.weeks))weeks=official.weeks;
    else if(typeof state!=='undefined'&&Array.isArray(state?.data?.weeks))weeks=state.data.weeks;
    const start=String(w?.dates?.[0]||'');
    return weeks.filter(x=>x&&x!==w&&String(x?.dates?.[0]||'')<start).sort((a,b)=>String(a.dates[0]).localeCompare(String(b.dates[0]))).at(-1)||null;
  }catch{return null}
}
function hasProtectedAbsence(arr){return (arr||[]).some(s=>['FERIE','MALATTIA','MATERNITÀ','PERMESSO'].includes(s))}
function exactSundayShift(s){return String(s||'').trim()==='08:00-13:00'}

validateWeek=function(w){
  const issues=[];
  if(!w||!Array.isArray(w.dates)||!w.schedule){issues.push('Turnazione non valida o incompleta');return issues}
  const aft=weekAfternoonGroup(w);
  const prev=previousWeekForRules(w);
  const prevAft=prev?weekAfternoonGroup(prev):null;

  // Rotazione settimanale: il gruppo pomeriggio deve cambiare rispetto alla settimana precedente.
  if(prevAft&&aft&&prevAft===aft)issues.push('Rotazione: Turno 1 / Turno 2 non hanno scambiato mattina e pomeriggio rispetto alla settimana precedente');

  w.dates.forEach((iso,i)=>{
    const day=new Date(iso+'T12:00:00').getDay();
    const active=Object.entries(w.schedule).filter(([,a])=>a[i]&&!ABSENCES.has(a[i]));

    // DOMENICA: esattamente 4, solo gruppo di competenza, tutti 08:00-13:00.
    if(day===0){
      if(active.length!==4)issues.push(`${fmtDate(iso)}: domenica ${active.length} persone invece di 4`);
      const wrongHours=active.filter(([,a])=>!exactSundayShift(a[i])).map(([n])=>n);
      if(wrongHours.length)issues.push(`${fmtDate(iso)}: domenica turno diverso da 08:00-13:00 (${wrongHours.join(', ')})`);
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
    const cash7=active.filter(([n,a])=>CASH.has(n)&&present(a[i],'07:00')).length;
    const cash1330=active.filter(([n,a])=>CASH.has(n)&&present(a[i],'13:30')).length;
    const r1=active.filter(([n,a])=>RESP.has(n)&&starts(a[i],'06:30')).length;
    const r2=active.filter(([n,a])=>RESP.has(n)&&present(a[i],'17:00')&&present(a[i],'20:29')).length;
    const central=active.filter(([,a])=>isCentralShift(a[i])).length;

    if(at630<2)issues.push(`${fmtDate(iso)}: solo ${at630} persone iniziano alle 06:30 (minimo 2)`);
    if(at7<4)issues.push(`${fmtDate(iso)}: solo ${at7} persone presenti alle 07:00 (minimo 4)`);
    if(close!==4)issues.push(`${fmtDate(iso)}: ${close} persone in chiusura invece di 4`);
    if(!r1)issues.push(`${fmtDate(iso)}: manca responsabile mattina alle 06:30`);
    if(!r2)issues.push(`${fmtDate(iso)}: manca responsabile pomeriggio/chiusura`);

    // Cassa: segnala la mancanza della copertura dedicata. La sala può essere usata solo come eccezione amministrativa.
    if(!cash7)issues.push(`${fmtDate(iso)}: manca cassa dedicata alle 07:00`);
    if(!cash1330)issues.push(`${fmtDate(iso)}: manca cassa dedicata alle 13:30`);

    // Lun / Mer / Gio: >=5 alle 11 e un solo centrale valido, indipendente dal ruolo.
    if([1,3,4].includes(day)){
      if(at11<5)issues.push(`${fmtDate(iso)}: ${at11} persone alle 11:00 invece di almeno 5`);
      if(central!==1)issues.push(`${fmtDate(iso)}: centrali = ${central} invece di 1`);
    }

    // Sabato nessun RIPOSO programmato.
    if(day===6){
      const rests=Object.entries(w.schedule).filter(([,a])=>a[i]==='RIPOSO').map(([n])=>n);
      if(rests.length)issues.push(`${fmtDate(iso)}: riposo sabato (${rests.join(', ')})`);
    }
  });

  // Ogni lavoratore del gruppo pomeriggio deve avere il riposo settimanale, salvo assenza protetta per tutta la settimana.
  if(aft){
    for(const n of aft){
      const arr=w.schedule[n]||[];
      const fullyAway=arr.every(s=>['FERIE','PERMESSO','MATERNITÀ','MALATTIA','—'].includes(s));
      if(!fullyAway&&!arr.includes('RIPOSO'))issues.push(`${n}: manca il riposo settimanale del turno pomeriggio`);
    }
  }

  // Ore contrattuali: non forzare le ore quando ci sono ferie/malattia/maternità/permesso.
  for(const n of Object.keys(w.schedule)){
    const arr=w.schedule[n]||[],h=weekHours(w,n);
    if(hasProtectedAbsence(arr))continue;
    if(n==='Marco'){
      if(w.dates.length===7&&h!==16)issues.push(`Marco: ${h}h invece di 16h`);
      continue;
    }
    if(n==='Giada'){
      if(w.dates.length===7&&h!==30)issues.push(`Giada: ${h}h invece di 30h`);
      continue;
    }
    if(!FORF.has(n)&&w.dates.length===7&&h<40)issues.push(`${n}: ${h}h invece delle 40h contrattuali`);
  }

  return [...new Set(issues)];
};