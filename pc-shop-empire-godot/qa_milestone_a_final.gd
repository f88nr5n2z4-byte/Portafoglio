extends SceneTree

var failures:Array = []

func check(condition:bool,message:String) -> void:
	if condition:
		print("MILESTONE A FINAL PASS: ",message)
	else:
		failures.append(message)
		printerr("MILESTONE A FINAL FAIL: ",message)

func add_part(game,id:String) -> void:
	game.inventory[id] = int(game.inventory.get(id,0)) + 1
	game._install_component(game._component(id))

func prepare_build(game) -> void:
	game.current_job = 0
	game.job_state = "working"
	game.build_slots.clear()
	game.inventory.clear()
	game.thermal_paste_applied = false
	game.cables_connected = false
	game.case_panel_open = false

func _init() -> void:
	var script:Script = load("res://qa_game.gd")
	check(script != null,"final runtime loads")
	if script == null:
		quit(1); return
	var game = script.new()
	game._load_data()

	# Visual tier coverage: entry / mid / high / enthusiast must map to different presentation tiers.
	check(game._hardware_tier(game._component("cpu_5600")) == 0,"entry hardware tier available")
	check(game._hardware_tier(game._component("gpu_5060")) >= 1,"mid-range hardware tier available")
	check(game._hardware_tier(game._component("gpu_5070_msi")) >= 2,"high-end hardware tier available")
	check(game._hardware_tier(game._component("gpu_5080")) == 3,"enthusiast hardware tier available")

	# Entry build.
	prepare_build(game)
	for id in ["case_atx","mb_b550","cpu_5600","ram_16_ddr4","ssd_1tb","psu_750","gpu_5060"]: add_part(game,id)
	game._apply_thermal_paste(); add_part(game,"cooler_air"); game._connect_cables(); game.case_panel_open=false
	check(game._build_ready(),"entry-level build finalizes")

	# Mid-range build.
	prepare_build(game)
	for id in ["case_lancool","mb_b850","cpu_9600x","ram_32","ssd_2tb","psu_850","gpu_5070_palit"]: add_part(game,id)
	game._apply_thermal_paste(); add_part(game,"cooler_air"); game._connect_cables(); game.case_panel_open=false
	check(game._build_ready(),"mid-range build finalizes")

	# High-end build with large GPU, strong PSU and AIO.
	prepare_build(game)
	for id in ["case_atx","mb_b850_aorus","cpu_9800x3d","ram_64","ssd_2tb","psu_1000","gpu_5080"]: add_part(game,id)
	game._apply_thermal_paste(); add_part(game,"cooler_aio"); game._connect_cables(); game.case_panel_open=false
	check(game._build_ready(),"high-end build finalizes")

	# Compatibility error must remain explicit.
	game.case_panel_open=true
	var bad_cpu:Dictionary = game._component("cpu_14600kf")
	check(game._compatibility_reason(bad_cpu).contains("socket"),"incompatible CPU reports socket reason")

	# Replace GPU.
	var previous_gpu:String = String(game.build_slots.get("GPU",""))
	game.inventory["gpu_9070xt"] = 1
	game._install_component(game._component("gpu_9070xt"))
	check(String(game.build_slots.get("GPU","")) == "gpu_9070xt","GPU replacement installs new model")
	check(int(game.inventory.get(previous_gpu,0)) >= 1,"GPU replacement returns previous model to inventory")

	# Remove storage and dependency-safe CPU removal.
	var storage_id:String = String(game.build_slots.get("Storage",""))
	var storage_before:int = int(game.inventory.get(storage_id,0))
	game._remove_component("Storage")
	check(not game.build_slots.has("Storage") and int(game.inventory.get(storage_id,0)) == storage_before+1,"storage removal returns part to inventory")
	var cpu_before:String = String(game.build_slots.get("CPU",""))
	game._remove_component("CPU")
	check(String(game.build_slots.get("CPU","")) == cpu_before,"CPU cannot be removed while cooler is installed")
	game._remove_component("Cooling"); game._remove_component("CPU")
	check(not game.build_slots.has("CPU"),"CPU removal works after cooler removal")

	# Partial assembly save/load persistence.
	prepare_build(game)
	for id in ["case_atx","mb_b850","cpu_9600x","ram_32"]: add_part(game,id)
	game.case_panel_open=true
	game._save_game()
	var saved_slots:Dictionary = game.build_slots.duplicate(true)
	game.build_slots.clear(); game.case_panel_open=false
	game._load_game()
	check(game.build_slots == saved_slots,"partial assembly slots survive save/load")
	check(game.case_panel_open,"panel state survives save/load")

	# Finalize complete machine: closed panel is mandatory.
	prepare_build(game)
	for id in ["case_atx","mb_b850","cpu_9600x","ram_32","ssd_1tb","psu_750","gpu_5060"]: add_part(game,id)
	game._apply_thermal_paste(); add_part(game,"cooler_air"); game._connect_cables()
	check(not game._build_ready(),"open panel blocks finalization")
	game.case_panel_open=false
	check(game._build_ready(),"closed panel allows final PC test")
	check(game.install_fx_duration > 0.0,"installation animation timing enabled")

	if failures.is_empty():
		print("PC GAME EMPIRE MILESTONE A FINAL QA: ALL TESTS PASSED")
		quit(0)
	else:
		printerr("PC GAME EMPIRE MILESTONE A FINAL QA: ",failures.size()," FAILURE(S)")
		quit(1)
