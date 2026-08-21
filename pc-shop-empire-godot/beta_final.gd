extends "res://beta_release.gd"

var thermal_paste_applied := false
var cables_connected := false
var os_installed := false
var os_install_progress := 0.0
var os_installing := false

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if screen=="os_install" and os_installing:
		os_install_progress=min(100.0,os_install_progress+delta*34.0)
		if os_install_progress>=100.0:
			os_installing=false; os_installed=true; tutorial_step=max(tutorial_step,9)
			_notify("Sistema operativo installato e configurato")
			_beep(980,0.16,"sfx")
			_autosave()
			# Keep result visible briefly through the completed installation screen.
		queue_redraw()

func _input(event: InputEvent) -> void:
	if screen=="os_install" and event.is_action_pressed("cancel") and not os_installing:
		screen="benchmark"; queue_redraw(); return
	super._input(event)

func _mouse_down(p:Vector2) -> void:
	if screen=="build":
		if _btn(390,930,330,70).has_point(p):
			_apply_thermal_paste(); return
		if _btn(760,930,330,70).has_point(p):
			_connect_cables(); return
	if screen=="benchmark":
		var j:=_job()
		if not j.is_empty() and bool(j.get("os_required",false)) and not os_installed:
			if _btn(1180,900,600,80).has_point(p):
				screen="os_install"; os_installing=true; os_install_progress=0.0; _beep(620,0.08,"ui"); queue_redraw()
			return
		if _btn(1460,900,360,80).has_point(p):
			var reason:=_job_validation_reason()
			if reason!="": _notify(reason,false); _beep(190,0.14,"sfx"); return
	if screen=="os_install":
		if not os_installing and os_installed and _btn(730,810,460,75).has_point(p): screen="benchmark"; queue_redraw()
		return
	super._mouse_down(p)

func _draw() -> void:
	if screen=="os_install": _draw_os_install(); return
	super._draw()

func _install_component(c:Dictionary) -> void:
	if String(c.category)=="Cooling" and not thermal_paste_applied:
		_notify("Prima applica la pasta termica sulla CPU",false); _beep(180,0.12,"sfx"); return
	super._install_component(c)

func _apply_thermal_paste() -> void:
	var j:=_job(); if j.is_empty(): return
	var allowed:=build_slots.has("CPU") or String(j.get("fault",""))=="Cooling"
	if not allowed: _notify("Installa prima la CPU",false); return
	if thermal_paste_applied: _notify("Pasta termica già applicata"); return
	thermal_paste_applied=true; _notify("Pasta termica applicata correttamente"); _beep(720,0.10,"sfx"); _autosave(); queue_redraw()

func _connect_cables() -> void:
	var j:=_job(); if j.is_empty(): return
	if String(j.type)!="build": _notify("Cablaggio principale già presente sul PC del cliente"); cables_connected=true; return
	if not (build_slots.has("Motherboard") and build_slots.has("PSU")):
		_notify("Installa scheda madre e alimentatore prima dei cavi",false); return
	cables_connected=true; _notify("24-pin, CPU EPS, GPU e front panel collegati"); _beep(760,0.10,"sfx"); _autosave(); queue_redraw()

func _build_ready() -> bool:
	if not super._build_ready(): return false
	var j:=_job(); if j.is_empty(): return false
	if String(j.type)=="build" and not (thermal_paste_applied and cables_connected): return false
	if String(j.get("fault",""))=="Cooling" and not thermal_paste_applied: return false
	return true

func _offer_next_job() -> void:
	thermal_paste_applied=false; cables_connected=false; os_installed=false; os_install_progress=0.0; os_installing=false
	super._offer_next_job()

func _finish_job() -> void:
	var reason:=_job_validation_reason()
	if reason!="": _notify(reason,false); _beep(180,0.14,"sfx"); return
	super._finish_job()
	thermal_paste_applied=false; cables_connected=false; os_installed=false; os_install_progress=0.0

func _job_validation_reason() -> String:
	var j:=_job(); if j.is_empty(): return "Nessun lavoro attivo"
	if not _build_ready() and String(j.type)!="repair": return "Assemblaggio non completato"
	if bool(j.get("os_required",false)) and not os_installed: return "Installa il sistema operativo prima della consegna"
	if String(j.type)=="build":
		var cost:=_build_cost()
		if cost>int(j.budget): return "Preventivo fuori budget: €%d / €%d"%[cost,int(j.budget)]
	var min_score:=float(j.get("min_score",0))
	if min_score>0 and _build_score()<min_score: return "Prestazioni insufficienti per la richiesta del cliente"
	var pref:=String(j.get("preferred",""))
	if pref!="":
		var gpu:=_component(String(build_slots.get("GPU","")))
		var cpu:=_component(String(build_slots.get("CPU","")))
		if pref=="NVIDIA" and not String(gpu.get("name","")).contains("GeForce"): return "Il cliente ha richiesto una GPU NVIDIA"
		if pref=="AMD" and not (String(cpu.get("name","")).begins_with("AMD") and (String(gpu.get("name","")).contains("Radeon") or String(gpu.get("name","")).begins_with("AMD"))): return "Il cliente ha richiesto una configurazione AMD"
	return ""

func _build_cost() -> int:
	var total:=0
	for k in build_slots:
		var c:=_component(String(build_slots[k])); total+=int(c.get("price",0))
	return total

func _draw_build() -> void:
	super._draw_build()
	var j:=_job()
	var paste_needed:=not thermal_paste_applied
	var cable_needed:=not cables_connected and not j.is_empty() and String(j.type)=="build"
	_button(_btn(390,930,330,70),("✓ PASTA TERMICA" if thermal_paste_applied else "APPLICA PASTA TERMICA"),paste_needed)
	_button(_btn(760,930,330,70),("✓ CAVI COLLEGATI" if cables_connected else "COLLEGA CAVI"),cable_needed)
	if not j.is_empty() and String(j.type)=="build":
		_txt(Vector2(1130,1000),"Costo build €%d / Budget €%d"%[_build_cost(),int(j.budget)],16,GREEN if _build_cost()<=int(j.budget) else RED)

func _draw_job_offer() -> void:
	super._draw_job_offer()
	var j:=_job(); if j.is_empty(): return
	var y:=570
	if float(j.get("min_score",0))>0: _txt(Vector2(220,y),"Prestazioni richieste: indice ≥ %.0f"%float(j.min_score),19,CYAN); y+=38
	if String(j.get("preferred",""))!="": _txt(Vector2(220,y),"Preferenza hardware: "+String(j.preferred),19,YELLOW); y+=38
	if bool(j.get("os_required",false)): _txt(Vector2(220,y),"Sistema operativo: installazione richiesta",19,WHITE)

func _draw_benchmark() -> void:
	super._draw_benchmark()
	var j:=_job(); if j.is_empty(): return
	_txt(Vector2(900,610),"Costo componenti: €%d"%_build_cost(),20,WHITE)
	if String(j.type)=="build": _txt(Vector2(900,650),"Budget cliente: €%d"%int(j.budget),20,GREEN if _build_cost()<=int(j.budget) else RED)
	if bool(j.get("os_required",false)) and not os_installed:
		draw_rect(Rect2(1120,850,720,145),Color(0.03,0.04,0.06,0.96),true)
		_button(_btn(1180,900,600,80),"INSTALLA SISTEMA OPERATIVO")
	elif bool(j.get("os_required",false)):
		_txt(Vector2(1210,865),"✓ SISTEMA OPERATIVO CONFIGURATO",18,GREEN)
	var reason:=_job_validation_reason()
	if reason!="" and not (bool(j.get("os_required",false)) and not os_installed): _txt(Vector2(180,790),reason,20,RED)

func _draw_os_install() -> void:
	_draw_header("CONFIGURAZIONE SOFTWARE")
	_panel(Rect2(430,190,1060,680),Color("#0b111a"),Color("#38485c"),3)
	_txt(Vector2(520,280),"PC GAME OS INSTALLER",34,WHITE)
	_txt(Vector2(520,345),"Installazione sistema • driver • aggiornamenti • configurazione",19,MUTED)
	var w:=820.0
	draw_rect(Rect2(550,470,w,28),Color("#222a35"),true)
	draw_rect(Rect2(550,470,w*os_install_progress/100.0,28),CYAN,true)
	_txt(Vector2(905,550),"%d%%"%int(os_install_progress),34,WHITE)
	var stage="Preparazione disco"
	if os_install_progress>25: stage="Copia file di sistema"
	if os_install_progress>55: stage="Installazione driver"
	if os_install_progress>78: stage="Configurazione e aggiornamenti"
	if os_install_progress>=100: stage="Installazione completata"
	_txt(Vector2(760,620),stage,22,GREEN if os_install_progress>=100 else MUTED)
	if os_install_progress>=100: _button(_btn(730,810,460,75),"TORNA AI TEST")

func _save_game() -> void:
	super._save_game()
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); if not f: return
	var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY: return
	d["thermal_paste_applied"]=thermal_paste_applied; d["cables_connected"]=cables_connected; d["os_installed"]=os_installed; d["os_install_progress"]=os_install_progress
	var w:=FileAccess.open(SAVE_PATH,FileAccess.WRITE); if w: w.store_string(JSON.stringify(d))

func _load_game() -> void:
	super._load_game()
	if not FileAccess.file_exists(SAVE_PATH): return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); if not f: return
	var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY: return
	thermal_paste_applied=bool(d.get("thermal_paste_applied",false)); cables_connected=bool(d.get("cables_connected",false)); os_installed=bool(d.get("os_installed",false)); os_install_progress=float(d.get("os_install_progress",0.0))
