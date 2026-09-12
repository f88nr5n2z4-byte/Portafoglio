extends RefCounted

# Milestone A domain model for the new real-time world.
# It deliberately has no dependency on the legacy beta CanvasItem or raster presentation.

const DEFAULT_REQUIRED:Array[String]=["CPU","Motherboard","RAM","GPU","Storage","PSU","Case","Cooling"]

var components:Array[Dictionary]=[]
var component_index:Dictionary={}
var inventory:Dictionary={}
var slots:Dictionary={}
var case_panel_open:=false
var thermal_paste_applied:=false
var cables_connected:=false

func load_component_database(path:String="res://data/components.json")->bool:
	components.clear(); component_index.clear()
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return false
	var parsed:Variant=JSON.parse_string(file.get_as_text())
	if typeof(parsed)!=TYPE_ARRAY: return false
	for raw:Variant in parsed:
		if typeof(raw)!=TYPE_DICTIONARY: continue
		var component:Dictionary=(raw as Dictionary).duplicate(true)
		var id:=String(component.get("id",""))
		if id.is_empty(): continue
		components.append(component); component_index[id]=component
	return not components.is_empty()

func begin_build()->void:
	slots.clear(); case_panel_open=false; thermal_paste_applied=false; cables_connected=false

func component(id:String)->Dictionary:
	return (component_index.get(id,{}) as Dictionary).duplicate(true)

func add_inventory(id:String,quantity:int=1)->Dictionary:
	if not component_index.has(id): return _result(false,"Componente sconosciuto: "+id)
	if quantity<=0: return _result(false,"Quantità non valida")
	inventory[id]=int(inventory.get(id,0))+quantity
	return _result(true,"Aggiunto all'inventario: "+String(component_index[id].get("name",id)))

func install(id:String)->Dictionary:
	var candidate:=component(id)
	if candidate.is_empty(): return _result(false,"Componente sconosciuto: "+id)
	if int(inventory.get(id,0))<=0: return _result(false,"Componente non disponibile nell'inventario")
	var category:=String(candidate.get("category",""))
	if category.is_empty(): return _result(false,"Categoria componente mancante")
	if category!="Case" and not slots.has("Case"): return _result(false,"Installa prima il case")
	if category!="Case" and not case_panel_open: return _result(false,"Apri il pannello del case per lavorare")
	var reason:=compatibility_reason(candidate)
	if not reason.is_empty(): return _result(false,reason)
	if slots.has(category):
		var previous:=String(slots[category]); inventory[previous]=int(inventory.get(previous,0))+1
	slots[category]=id; inventory[id]=maxi(0,int(inventory.get(id,0))-1)
	if category=="Case": case_panel_open=true
	if category in ["Motherboard","PSU","GPU"]: cables_connected=false
	if category in ["CPU","Cooling"]: thermal_paste_applied=false
	return _result(true,"Installato: "+String(candidate.get("name",id)),category)

func remove(category:String)->Dictionary:
	if not slots.has(category): return _result(false,"Slot già vuoto",category)
	if category=="Case" and slots.size()>1: return _result(false,"Rimuovi prima i componenti interni",category)
	if category=="Motherboard" and (slots.has("CPU") or slots.has("RAM") or slots.has("Cooling")):
		return _result(false,"Rimuovi CPU, RAM e dissipatore prima della motherboard",category)
	if category=="CPU" and slots.has("Cooling"): return _result(false,"Rimuovi prima il dissipatore",category)
	var id:=String(slots[category]); slots.erase(category); inventory[id]=int(inventory.get(id,0))+1
	if category in ["Motherboard","PSU","GPU"]: cables_connected=false
	if category in ["CPU","Cooling"]: thermal_paste_applied=false
	if category=="Case": case_panel_open=false
	return _result(true,"Rimosso: "+String(component_index.get(id,{}).get("name",id)),category)

func toggle_case_panel()->Dictionary:
	if not slots.has("Case"): return _result(false,"Installa prima il case","Case")
	case_panel_open=not case_panel_open
	return _result(true,"Pannello aperto" if case_panel_open else "Pannello chiuso","Case")

func apply_thermal_paste()->Dictionary:
	if not case_panel_open: return _result(false,"Apri il pannello del case","CPU")
	if not slots.has("CPU"): return _result(false,"Installa prima la CPU","CPU")
	thermal_paste_applied=true
	return _result(true,"Pasta termica applicata","CPU")

func connect_cables()->Dictionary:
	if not case_panel_open: return _result(false,"Apri il pannello del case","Motherboard")
	if not slots.has("Motherboard") or not slots.has("PSU"):
		return _result(false,"Installa motherboard e alimentatore","Motherboard")
	cables_connected=true
	return _result(true,"Cablaggio principale collegato","Motherboard")

func compatibility_reason(candidate:Dictionary)->String:
	var category:=String(candidate.get("category",""))
	if category=="CPU" and slots.has("Motherboard"):
		var mb:=component(String(slots["Motherboard"]))
		if String(candidate.get("socket",""))!=String(mb.get("socket","")): return "CPU incompatibile: socket differente"
	if category=="Motherboard":
		if slots.has("CPU"):
			var cpu:=component(String(slots["CPU"]))
			if String(candidate.get("socket",""))!=String(cpu.get("socket","")): return "Scheda madre incompatibile con la CPU"
		if slots.has("RAM"):
			var ram:=component(String(slots["RAM"]))
			if String(candidate.get("ram",""))!=String(ram.get("ram","")): return "Scheda madre incompatibile con la RAM installata"
		if slots.has("Case") and not _case_supports_form(component(String(slots["Case"])),String(candidate.get("form","ATX"))):
			return "Scheda madre incompatibile: form factor non supportato dal case"
	if category=="RAM" and slots.has("Motherboard"):
		var mb_ram:=component(String(slots["Motherboard"]))
		if String(candidate.get("ram",""))!=String(mb_ram.get("ram","")): return "RAM incompatibile: la motherboard usa "+String(mb_ram.get("ram","un'altra generazione"))
	if category=="Case":
		if slots.has("Motherboard") and not _case_supports_form(candidate,String(component(String(slots["Motherboard"])).get("form","ATX"))): return "Case incompatibile con la motherboard"
		if slots.has("GPU") and int(component(String(slots["GPU"])).get("length",0))>int(candidate.get("gpu_max",999)): return "Case incompatibile: GPU troppo lunga"
		if slots.has("Cooling"):
			var case_cooling:=_case_cooling_reason(candidate,component(String(slots["Cooling"])))
			if not case_cooling.is_empty(): return case_cooling
	if category=="GPU":
		if slots.has("Case") and int(candidate.get("length",0))>int(component(String(slots["Case"])).get("gpu_max",999)): return "GPU troppo lunga per il case"
		if slots.has("PSU") and int(component(String(slots["PSU"])).get("watts",0))<_recommended_psu_watts(candidate): return "Alimentatore insufficiente per la GPU"
	if category=="PSU" and int(candidate.get("watts",0))<_recommended_psu_watts({}): return "Alimentatore insufficiente: servono almeno %dW"%_recommended_psu_watts({})
	if category=="Cooling":
		if slots.has("CPU") and String(component(String(slots["CPU"])).get("socket","")) not in (candidate.get("sockets",[]) as Array): return "Dissipatore incompatibile con il socket"
		if slots.has("Case"):
			var cooling_reason:=_case_cooling_reason(component(String(slots["Case"])),candidate)
			if not cooling_reason.is_empty(): return cooling_reason
	return ""

func current_compatibility_reason()->String:
	for category:Variant in slots.keys():
		var installed:=component(String(slots[category]))
		var reason:=compatibility_reason(installed)
		if not reason.is_empty(): return reason
	return ""

func build_ready(required:Array[String]=DEFAULT_REQUIRED)->bool:
	for category:String in required:
		if not slots.has(category): return false
	if not current_compatibility_reason().is_empty(): return false
	if slots.has("CPU") and slots.has("Cooling") and not thermal_paste_applied: return false
	if slots.has("Motherboard") and slots.has("PSU") and not cables_connected: return false
	return not case_panel_open

func build_cost()->int:
	var total:=0
	for id:Variant in slots.values(): total+=int(component(String(id)).get("price",0))
	return total

func build_score()->int:
	var total:=0
	for id:Variant in slots.values(): total+=int(component(String(id)).get("score",0))
	return total

func snapshot()->Dictionary:
	return {"inventory":inventory.duplicate(true),"slots":slots.duplicate(true),"case_panel_open":case_panel_open,"thermal_paste_applied":thermal_paste_applied,"cables_connected":cables_connected}

func restore(data:Dictionary)->bool:
	var restored_inventory:Variant=data.get("inventory",{})
	var restored_slots:Variant=data.get("slots",{})
	if typeof(restored_inventory)!=TYPE_DICTIONARY or typeof(restored_slots)!=TYPE_DICTIONARY: return false
	inventory=(restored_inventory as Dictionary).duplicate(true); slots=(restored_slots as Dictionary).duplicate(true)
	for id:Variant in slots.values():
		if not component_index.has(String(id)): return false
	case_panel_open=bool(data.get("case_panel_open",false)); thermal_paste_applied=bool(data.get("thermal_paste_applied",false)); cables_connected=bool(data.get("cables_connected",false))
	return true

func _case_supports_form(case_component:Dictionary,form:String)->bool:
	var supported:Array=case_component.get("supported_forms",[]) as Array
	if not supported.is_empty(): return form in supported
	var case_form:=String(case_component.get("form","ATX"))
	if case_form=="ATX": return form in ["ATX","mATX","ITX"]
	if case_form=="mATX": return form in ["mATX","ITX"]
	return form==case_form

func _case_cooling_reason(case_component:Dictionary,cooling:Dictionary)->String:
	if String(cooling.get("kind","air"))=="aio":
		var radiator:=int(cooling.get("radiator",0)); var maximum:=int(case_component.get("rad_max",0))
		if radiator>0 and maximum>0 and radiator>maximum: return "AIO incompatibile: radiatore %d mm, massimo %d mm"%[radiator,maximum]
	else:
		var height:=int(cooling.get("height",0)); var height_max:=int(case_component.get("cooler_max",0))
		if height>0 and height_max>0 and height>height_max: return "Dissipatore troppo alto: %d mm, limite %d mm"%[height,height_max]
	return ""

func _recommended_psu_watts(candidate_gpu:Dictionary)->int:
	var cpu_power:=65
	if slots.has("CPU"): cpu_power=int(component(String(slots["CPU"])).get("power",65))
	var gpu_power:=0
	if not candidate_gpu.is_empty(): gpu_power=int(candidate_gpu.get("power",0))
	elif slots.has("GPU"): gpu_power=int(component(String(slots["GPU"])).get("power",0))
	return int(ceil(float(cpu_power+gpu_power+150)*1.20/50.0)*50.0)

func _result(ok:bool,message:String,category:String="")->Dictionary:
	return {"ok":ok,"message":message,"category":category}
