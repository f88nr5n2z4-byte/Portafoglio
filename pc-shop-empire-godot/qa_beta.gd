extends SceneTree

var failures := []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("QA FAIL: ", message)
	else:
		print("QA PASS: ", message)

func _init() -> void:
	var game_script := load("res://qa_game.gd")
	check(game_script != null, "final beta runtime script loads")
	if game_script == null:
		quit(1)
		return
	var game = game_script.new()
	game._load_data()
	check(game.components.size() >= 30, "expanded hardware catalog loaded")
	check(game.jobs.size() >= 15, "expanded customer job catalog loaded")
	game._new_game()
	check(game.money == 2000, "new game starts with 2000 euro")
	check(game.current_job == 0, "first customer job is offered")
	game.job_state = "accepted"
	var before_cooler := ["cpu_9600x","mb_b850","ram_32","gpu_5060","ssd_1tb","psu_750","case_atx"]
	for id in before_cooler:
		game.inventory[id] = 1
		var c: Dictionary = game._component(id)
		check(not c.is_empty(), "component exists: " + id)
		check(game._compatibility_reason(c) == "", "compatible component accepted: " + id)
		game._install_component(c)
	game._apply_thermal_paste()
	check(game.thermal_paste_applied, "thermal paste step completes")
	game.inventory["cooler_air"] = 1
	game._install_component(game._component("cooler_air"))
	game._connect_cables()
	check(game.cables_connected, "main cable step completes")
	check(game._build_ready(), "first PC hardware build becomes complete")
	check(game._build_cost() <= int(game._job().budget), "first build respects customer budget")
	check(game._build_score() >= float(game._job().min_score), "first build meets performance target")
	check(game._job_validation_reason().contains("sistema operativo"), "delivery blocked before OS installation")
	game.os_installed = true
	check(game._job_validation_reason() == "", "completed PC satisfies customer requirements")
	var before_money: int = game.money
	game._finish_job()
	check(game.money > before_money, "completed job pays the player")
	check(game.reputation > 0, "completed job adds reputation")
	check(game.completed_jobs == 1, "completed job counter increments")
	game._save_game()
	check(FileAccess.file_exists(game.SAVE_PATH), "save file created")
	var saved_money: int = game.money
	game.money = 1
	game._load_game()
	check(game.money == saved_money, "load restores economy")
	# Repair path: diagnosis first, then correct PSU replacement.
	game.current_job = 1
	game.job_state = "accepted"
	game.diagnostics_done = ["Power","POST"]
	check(game._diagnosis_revealed(), "repair diagnosis requires tests and reveals fault")
	game.build_slots.clear()
	game.inventory["psu_750"] = 1
	game._install_component(game._component("psu_750"))
	check(game._build_ready(), "repair completes after correct replacement")
	# Compatibility failure path.
	var incompatible_cpu: Dictionary = game._component("cpu_14600kf")
	game.build_slots = {"Motherboard":"mb_b850"}
	check(game._compatibility_reason(incompatible_cpu) != "", "socket mismatch is rejected")
	# Persistence and release-only systems.
	game.settings.resolution = "1280x720"
	game.settings.language = "en"
	game.language = "en"
	game._save_settings()
	check(FileAccess.file_exists(game.SETTINGS_PATH), "settings file created")
	game.money = 5000
	game.upgrades.Showroom = 1
	check(int(game.upgrades.Showroom) == 1, "shop upgrade state is writable")
	game.damaged_inventory["cpu_14600kf"] = 1
	check(game._compatibility_reason(incompatible_cpu).contains("guasto"), "damaged used component is rejected")
	game.pending_orders = [{"id":"ssd_2tb","name":"Crucial P310 NVMe 2TB","arrival_day":game.day,"arrival_hour":game.hour-0.01}]
	game._check_deliveries()
	check(int(game.inventory.get("ssd_2tb",0)) >= 1, "pending order reaches inventory")
	if failures.is_empty():
		print("PC GAME EMPIRE BETA QA: ALL TESTS PASSED")
		quit(0)
	else:
		printerr("PC GAME EMPIRE BETA QA: ", failures.size(), " FAILURE(S)")
		quit(1)
