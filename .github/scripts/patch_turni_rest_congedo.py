from pathlib import Path

# Final UI/routing patch: RIPOSO stays the weekly rest; add CONGEDO everywhere relevant.
p = Path('turni-v2/app-current.js')
s = p.read_text()

s = s.replace("const OFF=new Set(['RIPOSO','FERIE','PERMESSO','MALATTIA','MATERNITÀ','—','']);", "const OFF=new Set(['RIPOSO','FERIE','PERMESSO','CONGEDO','MALATTIA','MATERNITÀ','—','']);")
s = s.replace("'RIPOSO','FERIE','PERMESSO','MALATTIA'];", "'RIPOSO','FERIE','PERMESSO','CONGEDO','MALATTIA'];")

old = '<button data-kind="RIPOSO"><span>▣</span><b>Giorno di riposo</b><i>›</i></button><button data-kind="ALTRO">'
new = '<button data-kind="RIPOSO"><span>▣</span><b>Giorno di riposo</b><i>›</i></button><button data-kind="CONGEDO"><span>◫</span><b>Congedo</b><i>›</i></button><button data-kind="ALTRO">'
if old not in s:
    raise SystemExit('request menu target not found')
s = s.replace(old, new, 1)

old = "${['FERIE','PERMESSO'].includes(real)?`<label><span>Fino al</span><input id=\"reqEnd\" type=\"date\" value=\"${esc(presetDate)}\"></label>`:''}"
new = "${['FERIE','PERMESSO','CONGEDO'].includes(real)?`<label><span>Fino al</span><input id=\"reqEnd\" type=\"date\" value=\"${esc(presetDate)}\"></label>`:''}"
if old not in s:
    raise SystemExit('request range target not found')
s = s.replace(old, new, 1)
s = s.replace("!['FERIE','PERMESSO','MALATTIA'].includes(x)", "!['FERIE','PERMESSO','CONGEDO','MALATTIA'].includes(x)")
s = s.replace("['RIPOSO','TURNO'].includes(String(r.kind).toUpperCase())", "['RIPOSO','TURNO','CONGEDO'].includes(String(r.kind).toUpperCase())")
s = s.replace("['RIPOSO','TURNO'].includes(String(x.kind).toUpperCase())", "['RIPOSO','TURNO','CONGEDO'].includes(String(x.kind).toUpperCase())")

start = s.find('function absencesView(){')
end = s.find('\n\nfunction hoursView()', start)
if start < 0 or end < 0:
    raise SystemExit('absencesView boundaries not found')
new_view = '''function absencesView(){
  const accepted=(S.requests||[]).filter(r=>r.status==='ACCETTATA'&&['FERIE','PERMESSO','RIPOSO','CONGEDO'].includes(String(r.kind||'').toUpperCase())).map(r=>({id:null,employee_name:r.employee_name,absence_type:String(r.kind).toUpperCase(),date_from:r.request_date,date_to:r.end_date||r.request_date,fromRequest:true,requestId:r.id}));
  const key=a=>[a.employee_name,String(a.absence_type||'').toUpperCase(),a.date_from,a.date_to||a.date_from].join('|');
  const existing=new Set((S.absences||[]).map(key));
  const rows=[...(S.absences||[]),...accepted.filter(a=>!existing.has(key(a)))].sort((a,b)=>String(b.date_from||'').localeCompare(String(a.date_from||'')));
  return shell(`<section class="form-card"><h3>Aggiungi assenza</h3><div class="form-grid"><label><span>Dipendente</span><select id="absPerson">${PEOPLE.map(n=>`<option>${esc(n)}</option>`).join('')}</select></label><label><span>Tipo</span><select id="absType"><option>FERIE</option><option>PERMESSO</option><option>RIPOSO</option><option>CONGEDO</option><option>MALATTIA</option></select></label><label><span>Dal</span><input id="absFrom" type="date"></label><label><span>Al</span><input id="absTo" type="date"></label></div><button class="btn primary" id="addAbs">Aggiungi</button><div class="info-box">ⓘ Un RIPOSO inserito o accettato come richiesta vale come riposo settimanale: il generatore non aggiunge un secondo riposo.</div></section><section class="list-card"><h3>Ferie e assenze inserite</h3>${rows.length?`<div class="absence-list">${rows.map(a=>`<div><span class="absence-icon">${String(a.absence_type).toUpperCase()==='RIPOSO'?'▣':String(a.absence_type).toUpperCase()==='CONGEDO'?'◫':'☂'}</span><div><b>${esc(a.employee_name)}</b><small>${esc(a.absence_type)} · ${esc(a.date_from)} → ${esc(a.date_to||a.date_from)}${a.fromRequest?' · richiesta accettata':''}</small></div>${a.fromRequest?'':`<button data-delabs="${a.id}">×</button>`}</div>`).join('')}</div>`:'<div class="empty-mini">Nessuna assenza inserita.</div>'}</section>`)
}'''
s = s[:start] + new_view + s[end:]
s = s.replace('current-20260913-3','current-20260913-5').replace('current-20260913-4','current-20260913-5')
p.write_text(s)

ip = Path('turni-v2/index.html')
x = ip.read_text().replace('current-20260913-3','current-20260913-5').replace('current-20260913-4','current-20260913-5')
ip.write_text(x)

sw = Path('turni-v2/sw.js')
x = sw.read_text().replace('turni-current-20260913-v3','turni-current-20260913-v5').replace('turni-current-20260913-v4','turni-current-20260913-v5')
sw.write_text(x)
