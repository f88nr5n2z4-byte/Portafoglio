(()=>{
 const baseSuggestions=suggestions;
 function smartCentralSuggestions(){
   if(!candidate||wi<0||di<0)return[];
   const w=candidate.weeks[wi],issues=problems(),joined=issues.join(' | ');
   if(!/centrali\s*=\s*0|centrali sala\s*=\s*0/.test(joined))return[];
   const options=['10:00-17:00','10:00-18:00','10:00-19:00','11:00-18:00','11:00-20:00','11:00-20:30','12:00-20:00','12:00-20:30'];
   const names=Object.keys(w.schedule),base=validateWeek(w).length,best=[];
   for(const n of names){
     if(n===req.employee)continue;
     const current=w.schedule[n][di]||'—';
     if(ABSENCES.has(current))continue;
     for(const s of options){
       if(s===current)continue;
       const sim=structuredClone(w);
       sim.schedule[n][di]=s;
       const after=validateWeek(sim),count=after.length;
       if(count<base){
         const closesBefore=present(current,'20:29'),closesAfter=present(s,'20:29');
         best.push({n,current,s,count,delta:base-count,closureChange:closesBefore!==closesAfter});
       }
     }
   }
   best.sort((a,b)=>b.delta-a.delta||a.count-b.count||Number(a.closureChange)-Number(b.closureChange));
   const picked=[],seen=new Set();
   for(const x of best){
     if(seen.has(x.n))continue;
     seen.add(x.n);picked.push(x);
     if(picked.length>=3)break;
   }
   return picked.map(x=>`Per creare il centrale, valuterei ${x.n}: ${x.current} → ${x.s}. Gli errori scenderebbero da ${base} a ${x.count}.`);
 }
 suggestions=function(){
   const smart=smartCentralSuggestions();
   const base=baseSuggestions();
   if(!smart.length)return base;
   const rest=base.filter(x=>!/Scambio consigliato|Proverei /.test(x));
   return [...smart,...rest];
 };
})();