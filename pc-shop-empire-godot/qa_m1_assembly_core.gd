extends SceneTree

const AssemblyCore=preload("res://game/systems/assembly_core.gd")
var failures:Array[String]=[]

func check(condition:bool,message:String)->void:
	if condition: print("M1 ASSEMBLY CORE PASS: ",message)
	else: failures.append(message); printerr("M1 ASSEMBLY CORE FAIL: ",message)

func grant(core:RefCounted,ids:Array[String])->void:
	for id:String in ids: check(bool(core.add_inventory(id).get("ok",false)),"inventory accepts "+id)

func install(core:RefCounted,id:String)->void:
	check(bool(core.install(id).get("ok",false)),"installs "+id)

func _init()->void:
	var core=AssemblyCore.new()
	check(core.load_component_database(),"real component database loads")
	check(core.components.size()>=30,"commercial component catalogue is available")
	core.begin_build()
	grant(core,["case_atx","mb_b850","cpu_9600x","cpu_14600kf","ram_32","ssd_1tb","psu_750","gpu_5060","cooler_air"])
	check(not bool(core.install("mb_b850").get("ok",true)),"case must be installed first")
	install(core,"case_atx"); install(core,"mb_b850")
	check(not bool(core.install("cpu_14600kf").get("ok",true)) and String(core.install("cpu_14600kf").get("message","")).contains("socket"),"socket mismatch is explicit")
	install(core,"cpu_9600x"); install(core,"ram_32"); install(core,"ssd_1tb"); install(core,"psu_750"); install(core,"gpu_5060")
	check(not core.build_ready(),"incomplete build cannot finalize")
	check(bool(core.apply_thermal_paste().get("ok",false)),"thermal paste operation is real")
	install(core,"cooler_air")
	# Installing the cooler deliberately invalidates paste, so it must be applied after seating.
	check(bool(core.apply_thermal_paste().get("ok",false)),"thermal paste can be reapplied after cooler seating")
	check(bool(core.connect_cables().get("ok",false)),"main cabling operation is real")
	check(bool(core.toggle_case_panel().get("ok",false)) and not core.case_panel_open,"case panel closes")
	check(core.build_ready(),"compatible complete machine is ready")
	check(core.build_cost()>0 and core.build_score()>0,"build cost and score are computed")
	var saved:=core.snapshot(); var restored=AssemblyCore.new(); restored.load_component_database()
	check(restored.restore(saved) and restored.slots==core.slots,"partial/full assembly state round-trips")
	check(not bool(restored.remove("CPU").get("ok",true)),"CPU dependency blocks unsafe removal")
	check(bool(restored.toggle_case_panel().get("ok",false)),"panel reopens for service")
	check(bool(restored.remove("Cooling").get("ok",false)) and bool(restored.remove("CPU").get("ok",false)),"dependency-safe removal works")
	if failures.is_empty(): print("PC GAME EMPIRE M1 ASSEMBLY CORE QA: ALL TESTS PASSED"); quit(0)
	else: printerr("PC GAME EMPIRE M1 ASSEMBLY CORE QA: ",failures.size()," FAILURE(S)"); quit(1)
