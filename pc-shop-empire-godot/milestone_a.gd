extends "res://visual_upgrade_real.gd"

# PC GAME EMPIRE 1.0 — MILESTONE A
# Complete but accessible PC assembly + understandable compatibility.
# Detailed screws/pin-by-pin cabling are intentionally outside the 1.0 scope.

var case_panel_open := false
var assembly_last_action := ""

func _new_game() -> void:
	case_panel_open = false
	assembly_last_action = ""
	super._new_game()

func _offer_next_job() -> void:
	case_panel_open = false
	assembly_last_action = ""
	super._offer_next_job()

func _input(event: InputEvent) -> void:
	if screen == "build" and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_remove_component_at(mb.position)
			queue_redraw()
			return
	super._input(event)

func _mouse_down(p:Vector2) -> void:
	if screen == "build" and _btn(1110,930,340,70).has_point(p):
		_toggle_case_panel()
		return
	super._mouse_down(p)

func _toggle_case_panel() -> void:
	var j:Dictionary = _job()
	if j.is_empty():
		return
	if String(j.get("type","")) == "build" and not build_slots.has("Case"):
		_notify("Installa prima il case",false)
		return
	case_panel_open = not case_panel_open
	assembly_last_action = "Pannello aperto" if case_panel_open else "Pannello chiuso"
	_notify(assembly_last_action)
	_beep(620 if case_panel_open else 540,0.08,"sfx")
	_autosave()
	queue_redraw()

func _install_component(c:Dictionary) -> void:
	var j:Dictionary = _job()
	var cat:String = String(c.get("category",""))
	if not j.is_empty() and String(j.get("type","")) == "build":
		if cat != "Case" and not build_slots.has("Case"):
			_notify("Prima scegli e installa il case",false)
			_beep(180,0.12,"sfx")
			return
		if cat != "Case" and not case_panel_open:
			_notify("Apri il pannello del case per lavorare",false)
			_beep(180,0.12,"sfx")
			return
	var reason:String = _compatibility_reason(c)
	if reason != "":
		_notify(reason,false)
		_beep(180,0.12,"sfx")
		return
	var replacing := build_slots.has(cat)
	var old_id:String = String(build_slots.get(cat,""))
	super._install_component(c)
	if String(build_slots.get(cat,"")) != String(c.get("id","")):
		return
	if cat == "Case":
		case_panel_open = true
	if cat in ["Motherboard","PSU","GPU"]:
		cables_connected = false
	assembly_last_action = ("Sostituito: " if replacing and old_id != "" else "Installato: ") + String(c.get("name","Componente"))
	queue_redraw()

func _remove_component_at(p:Vector2) -> void:
	if build_slots.is_empty():
		return
	var best_cat := ""
	var best_area := 99999999.0
	var priority := ["CPU","RAM","Storage","Cooling","GPU","PSU","Fans","Motherboard","Case"]
	for cat_var in priority:
		var cat:String = String(cat_var)
		if not build_slots.has(cat):
			continue
		var r:Rect2 = _build_drop_rect(cat)
		if r.has_point(p):
			var area:float = r.size.x * r.size.y
			if area < best_area:
				best_area = area
				best_cat = cat
	if best_cat == "":
		return
	_remove_component(best_cat)

func _remove_component(cat:String) -> void:
	if not build_slots.has(cat):
		return
	if cat == "Case" and build_slots.size() > 1:
		_notify("Rimuovi prima i componenti interni",false)
		return
	if cat == "Motherboard" and (build_slots.has("CPU") or build_slots.has("RAM") or build_slots.has("Cooling")):
		_notify("Rimuovi CPU, RAM e dissipatore prima della motherboard",false)
		return
	if cat == "CPU" and build_slots.has("Cooling"):
		_notify("Rimuovi prima il dissipatore",false)
		return
	var id:String = String(build_slots[cat])
	var c:Dictionary = _component(id)
	inventory[id] = int(inventory.get(id,0)) + 1
	build_slots.erase(cat)
	if cat in ["Motherboard","PSU","GPU"]:
		cables_connected = false
	if cat == "CPU":
		thermal_paste_applied = false
	if cat == "Case":
		case_panel_open = false
	assembly_last_action = "Rimosso: " + String(c.get("name",cat))
	_notify(assembly_last_action)
	_beep(420,0.08,"sfx")
	_autosave()

func _compatibility_reason(c:Dictionary) -> String:
	var inherited_reason:String = super._compatibility_reason(c)
	if inherited_reason != "":
		return inherited_reason
	var cat:String = String(c.get("category",""))

	if cat == "Motherboard":
		if build_slots.has("Case"):
			var ca:Dictionary = _component(String(build_slots["Case"]))
			if not _case_supports_form(ca,String(c.get("form","ATX"))):
				return "Scheda madre incompatibile: form factor non supportato dal case"
		if build_slots.has("RAM"):
			var ram:Dictionary = _component(String(build_slots["RAM"]))
			if String(ram.get("ram","")) != String(c.get("ram","")):
				return "Scheda madre incompatibile: richiede " + String(c.get("ram","RAM diversa"))

	if cat == "RAM" and build_slots.has("Motherboard"):
		var mb:Dictionary = _component(String(build_slots["Motherboard"]))
		if String(c.get("ram","")) != String(mb.get("ram","")):
			return "RAM incompatibile: la motherboard usa " + String(mb.get("ram","un'altra generazione"))

	if cat == "Case":
		if build_slots.has("Motherboard"):
			var mb2:Dictionary = _component(String(build_slots["Motherboard"]))
			if not _case_supports_form(c,String(mb2.get("form","ATX"))):
				return "Case incompatibile: non supporta il form factor della motherboard"
		if build_slots.has("GPU"):
			var gpu:Dictionary = _component(String(build_slots["GPU"]))
			if int(gpu.get("length",0)) > int(c.get("gpu_max",999)):
				return "Case incompatibile: GPU troppo lunga (%d mm > %d mm)"%[int(gpu.get("length",0)),int(c.get("gpu_max",999))]
		if build_slots.has("Cooling"):
			var cooling:Dictionary = _component(String(build_slots["Cooling"]))
			var case_cooling_reason:String = _case_cooling_reason(c,cooling)
			if case_cooling_reason != "":
				return case_cooling_reason

	if cat == "GPU":
		if build_slots.has("Case"):
			var ca2:Dictionary = _component(String(build_slots["Case"]))
			if int(c.get("length",0)) > int(ca2.get("gpu_max",999)):
				return "GPU incompatibile: lunga %d mm, il case accetta fino a %d mm"%[int(c.get("length",0)),int(ca2.get("gpu_max",999))]
		if build_slots.has("PSU"):
			var psu:Dictionary = _component(String(build_slots["PSU"]))
			var required:int = _recommended_psu_watts(c)
			if int(psu.get("watts",0)) < required:
				return "GPU incompatibile con il PSU attuale: consigliati almeno %dW"%required

	if cat == "PSU":
		var required_psu:int = _recommended_psu_watts({})
		if int(c.get("watts",0)) < required_psu:
			return "PSU insufficiente: questa configurazione richiede almeno %dW"%required_psu

	if cat == "Cooling":
		if build_slots.has("Case"):
			var ca3:Dictionary = _component(String(build_slots["Case"]))
			var cooling_reason:String = _case_cooling_reason(ca3,c)
			if cooling_reason != "":
				return cooling_reason

	return ""

func _case_supports_form(case_component:Dictionary,form:String) -> bool:
	var supported:Array = case_component.get("supported_forms",[])
	if not supported.is_empty():
		return form in supported
	var case_form:String = String(case_component.get("form","ATX"))
	if case_form == "ATX":
		return form in ["ATX","mATX","ITX"]
	if case_form == "mATX":
		return form in ["mATX","ITX"]
	return form == case_form

func _case_cooling_reason(case_component:Dictionary,cooling:Dictionary) -> String:
	var kind:String = String(cooling.get("kind","air"))
	if kind == "aio":
		var radiator:int = int(cooling.get("radiator",0))
		var maximum:int = int(case_component.get("rad_max",0))
		if radiator > 0 and maximum > 0 and radiator > maximum:
			return "AIO incompatibile: radiatore %d mm, il case supporta fino a %d mm"%[radiator,maximum]
	else:
		var height:int = int(cooling.get("height",0))
		var height_max:int = int(case_component.get("cooler_max",0))
		if height > 0 and height_max > 0 and height > height_max:
			return "Dissipatore troppo alto: %d mm, limite case %d mm"%[height,height_max]
	return ""

func _recommended_psu_watts(candidate_gpu:Dictionary) -> int:
	var cpu_power := 65
	if build_slots.has("CPU"):
		var cpu:Dictionary = _component(String(build_slots["CPU"]))
		cpu_power = int(cpu.get("power",65))
	var gpu_power := 0
	if not candidate_gpu.is_empty() and String(candidate_gpu.get("category","")) == "GPU":
		gpu_power = int(candidate_gpu.get("power",0))
	elif build_slots.has("GPU"):
		var gpu:Dictionary = _component(String(build_slots["GPU"]))
		gpu_power = int(gpu.get("power",0))
	var base_system := 150
	var raw:int = cpu_power + gpu_power + base_system
	var with_headroom:float = float(raw) * 1.20
	return int(ceil(with_headroom / 50.0) * 50.0)

func _current_build_compatibility_reason() -> String:
	for cat_var in build_slots.keys():
		var cat:String = String(cat_var)
		var c:Dictionary = _component(String(build_slots[cat]))
		if c.is_empty():
			continue
		var reason:String = _compatibility_reason(c)
		if reason != "":
			return reason
	return ""

func _build_ready() -> bool:
	if not super._build_ready():
		return false
	var j:Dictionary = _job()
	if j.is_empty():
		return false
	if _current_build_compatibility_reason() != "":
		return false
	if String(j.get("type","")) == "build" and case_panel_open:
		return false
	return true

func _draw_build() -> void:
	super._draw_build()
	var j:Dictionary = _job()
	var is_full_build:bool = not j.is_empty() and String(j.get("type","")) == "build"
	var panel_label := "CHIUDI PANNELLO" if case_panel_open else "APRI PANNELLO"
	_button(_btn(1110,930,340,70),panel_label,not is_full_build or build_slots.has("Case"))
	var compatibility:String = _current_build_compatibility_reason()
	if compatibility == "":
		_txt(Vector2(320,118),"COMPATIBILITÀ ✓",16,GREEN)
	else:
		_txt(Vector2(320,118),compatibility,16,RED)
	var installed_count:int = build_slots.size()
	_txt(Vector2(620,118),"Componenti installati: %d"%installed_count,16,WHITE)
	_txt(Vector2(900,118),"Drag & drop • Click destro per rimuovere",14,MUTED)
	if is_full_build and case_panel_open:
		_txt(Vector2(1110,905),"Chiudi il pannello prima del test finale",14,YELLOW)

func _draw_case() -> void:
	super._draw_case()
	# Dynamic state overlays: the installed hardware is visibly present in the case.
	var order := ["Motherboard","PSU","Storage","CPU","RAM","GPU","Cooling","Fans"]
	for cat_var in order:
		var cat:String = String(cat_var)
		if not build_slots.has(cat):
			continue
		var c:Dictionary = _component(String(build_slots[cat]))
		var slot:Rect2 = _build_drop_rect(cat)
		var art_rect:Rect2 = slot.grow(-12.0)
		if art_rect.size.x > 30.0 and art_rect.size.y > 30.0:
			_draw_component_photo(art_rect,cat,abs(String(c.get("id","")).hash()) % 7)
		_panel(Rect2(slot.position+Vector2(8,8),Vector2(minf(250.0,slot.size.x-16.0),34)),Color(0.015,0.025,0.035,0.90),GREEN,1.0)
		_txt(slot.position+Vector2(15,31),"✓ "+String(c.get("name",cat)),12,WHITE)
	if build_slots.has("Case") and not case_panel_open:
		draw_rect(Rect2(330,175,950,720),Color(0.06,0.10,0.14,0.16),true)
		draw_rect(Rect2(330,175,950,720),Color(0.40,0.75,0.95,0.35),false,3.0)
		_txt(Vector2(690,870),"PANNELLO CHIUSO • PRONTO PER IL TEST",17,CYAN)

func _save_game() -> void:
	super._save_game()
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	d["case_panel_open"] = case_panel_open
	d["assembly_last_action"] = assembly_last_action
	var w:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if w:
		w.store_string(JSON.stringify(d))

func _load_game() -> void:
	super._load_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	case_panel_open = bool(d.get("case_panel_open",false))
	assembly_last_action = String(d.get("assembly_last_action",""))
