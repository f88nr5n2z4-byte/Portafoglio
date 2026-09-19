extends "res://beta_ship.gd"

func _job_validation_reason() -> String:
	var j:=_job()
	if j.is_empty():
		return "Nessun lavoro attivo"
	# Every job type, including repairs, must satisfy the actual work-complete predicate.
	# This prevents repaired jobs from being delivered after diagnosis only.
	if not _build_ready():
		return "Riparazione non completata" if String(j.type)=="repair" else "Assemblaggio non completato"
	if bool(j.get("os_required",false)) and not os_installed:
		return "Installa il sistema operativo prima della consegna"
	if String(j.type)=="build":
		var cost:=_build_cost()
		if cost>int(j.budget):
			return "Preventivo fuori budget: €%d / €%d"%[cost,int(j.budget)]
	var min_score:=float(j.get("min_score",0))
	if min_score>0 and _build_score()<min_score:
		return "Prestazioni insufficienti per la richiesta del cliente"
	var pref:=String(j.get("preferred",""))
	if pref!="":
		var gpu:=_component(String(build_slots.get("GPU","")))
		var cpu:=_component(String(build_slots.get("CPU","")))
		if pref=="NVIDIA" and not String(gpu.get("name","")).contains("GeForce"):
			return "Il cliente ha richiesto una GPU NVIDIA"
		if pref=="AMD" and not (String(cpu.get("name","")).begins_with("AMD") and (String(gpu.get("name","")).contains("Radeon") or String(gpu.get("name","")).begins_with("AMD"))):
			return "Il cliente ha richiesto una configurazione AMD"
	return ""

func _finish_job() -> void:
	# Guard against double payout / stale state and force validation immediately before payment.
	if current_job < 0 or job_state not in ["accepted","working","ready"]:
		_notify("Nessun lavoro pronto per la consegna",false)
		return
	var reason:=_job_validation_reason()
	if reason!="":
		_notify(reason,false)
		_beep(180,0.14,"sfx")
		return
	super._finish_job()
