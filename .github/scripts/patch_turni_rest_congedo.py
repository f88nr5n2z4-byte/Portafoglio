from pathlib import Path

p=Path('turni-v2/app-current.js')
s=p.read_text()
# Keep CONGEDO as an off-duty state, never as a requested working shift.
s=s.replace("!['FERIE','PERMESSO','MALATTIA'].includes(x)", "!['FERIE','PERMESSO','CONGEDO','MALATTIA'].includes(x)")
# Accepted RIPOSO already uses the weekly-rest constraint; also pass CONGEDO to generators that receive request payloads.
s=s.replace("['RIPOSO','TURNO'].includes(String(r.kind).toUpperCase())", "['RIPOSO','TURNO','CONGEDO'].includes(String(r.kind).toUpperCase())")
s=s.replace("['RIPOSO','TURNO'].includes(String(x.kind).toUpperCase())", "['RIPOSO','TURNO','CONGEDO'].includes(String(x.kind).toUpperCase())")
s=s.replace('current-20260913-3','current-20260913-5').replace('current-20260913-4','current-20260913-5')
p.write_text(s)

ip=Path('turni-v2/index.html')
ip.write_text(ip.read_text().replace('current-20260913-3','current-20260913-5').replace('current-20260913-4','current-20260913-5'))
sw=Path('turni-v2/sw.js')
sw.write_text(sw.read_text().replace('turni-current-20260913-v3','turni-current-20260913-v5').replace('turni-current-20260913-v4','turni-current-20260913-v5'))
