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
	check(game.components.size() >= 30, "hardware catalog loaded")
	check(game.jobs.size() >= 15, "customer/job catalog loaded")
	check(game.resolutions.has("1280x720") and game.resolutions.has("1366x768") and game.resolutions.has("1920x1080") and game.resolutions.has("2560x1440"), "required resolutions available")

	# Fresh game / first build end-to-end logic.
	game._new_game()
	check(game.money == 2000, "new game starts with 2000 euro")
	check(game.current_job == 0 and game.job_state == "offered", "first customer job is offered")
	game.job_state = "accepted"
	check(game._job_validation_reason() != "", "early delivery is rejected")
	var build_ids := ["cpu_9600x","mb_b850","ram_32","gpu_5060","ssd_1tb","psu_750","case_atx"]
	for id in build_ids:
		game.inventory[id] = 1
		var c: Dictionary = game._component(id)
		check(not c.is_empty(), "component exists: " + id)
		check(game._compatibility_reason(c) == "", "compatible component accepted: " + id)
		game._install_component(c)
	game._apply_thermal_paste()
	game.inventory["cooler_air"] = 1
	game._install_component(game._component("cooler_air"))
	game._connect_cables()
	check(game._build_ready(), "complete build is mechanically ready")
	check(game._build_cost() <= int(game._job().budget), "build respects customer budget")
	check(game._build_score() >= float(game._job().min_score), "build respects performance target")
	check(game._job_validation_reason().contains("sistema operativo"), "OS requirement blocks delivery")
	game.os_installed = true
	check(game._job_validation_reason() == "", "validated build becomes deliverable")
	var before_money: int = int(game.money)
	game._finish_job()
	check(game.money > before_money, "completed build pays the player")
	check(game.reputation > 0 and game.completed_jobs == 1, "completion grants reputation and progression")
	var paid_money: int = int(game.money)
	game._finish_job()
	check(game.money == paid_money, "double delivery cannot duplicate payment")

	# Save/load persistence.
	game._save_game()
	check(FileAccess.file_exists(game.SAVE_PATH), "save file created")
	var saved_money: int = int(game.money)
	game.money = 1
	game._load_game()
	check(game.money == saved_money, "load restores player balance")

	# Repair regression: diagnosis alone must NEVER complete the repair.
	game.current_job = 1 # repair_boot / PSU fault
	game.job_state = "accepted"
	game.diagnostics_done = ["Power","POST","PSU"]
	check(game._diagnosis_revealed(), "repair fault is revealed after diagnostic tests")
	check(not game._build_ready(), "diagnosis alone does not complete repair")
	var repair_money_before: int = int(game.money)
	game._finish_job()
	check(game.money == repair_money_before and game.job_state != "none", "premature repair delivery is rejected")
	game.job_state = "working"
	game.inventory["psu_750"] = 1
	game._install_component(game._component("psu_750"))
	check(game._build_ready(), "correct replacement completes PSU repair")
	check(game._job_validation_reason() == "", "completed repair passes delivery validation")
	game._finish_job()
	check(game.money > repair_money_before and game.job_state == "none", "correct repair pays once and closes job")
	var after_repair_money: int = int(game.money)
	game._finish_job()
	check(game.money == after_repair_money, "closed repair cannot pay twice")

	# Wrong repair / compatibility / damaged stock.
	game.current_job = 4 # RAM repair
	game.job_state = "working"
	game.diagnostics_done = ["POST","Memory","Stress"]
	game.build_slots.clear()
	game.inventory["psu_750"] = 1
	game._install_component(game._component("psu_750"))
	check(not game._build_ready(), "wrong replacement does not complete RAM repair")
	var incompatible_cpu: Dictionary = game._component("cpu_14600kf")
	game.build_slots = {"Motherboard":"mb_b850"}
	check(game._compatibility_reason(incompatible_cpu) != "", "CPU socket mismatch is rejected")
	game.damaged_inventory["cpu_14600kf"] = 1
	check(game._compatibility_reason(incompatible_cpu).contains("guasto"), "damaged used component is rejected")

	# Economy and order-delivery edge cases.
	game.money = 0
	var zero_money: int = int(game.money)
	check(zero_money < int(game._component("gpu_5060").price), "zero balance cannot afford purchase")
	game.money = 5000
	game.pending_orders.clear()
	game.pending_orders.append({"id":"ssd_1tb","name":"Samsung 990 EVO 1TB","arrival_day":game.day,"arrival_hour":game.hour})
	var inv_before: int = int(game.inventory.get("ssd_1tb",0))
	game._check_deliveries()
	check(int(game.inventory.get("ssd_1tb",0)) == inv_before + 1 and game.pending_orders.is_empty(), "arrived order transfers once into inventory")
	game._check_deliveries()
	check(int(game.inventory.get("ssd_1tb",0)) == inv_before + 1, "delivery cannot duplicate inventory")

	# Settings persistence / modes exposed by release build.
	game.settings.resolution = "1280x720"
	game.settings.window_mode = "Windowed"
	game.settings.language = "en"
	game.language = "en"
	game.settings.vsync = false
	game.settings.fps = 120
	game._save_settings()
	check(FileAccess.file_exists(game.SETTINGS_PATH), "settings file created")
	game.settings.resolution = "1920x1080"
	game.language = "it"
	game._load_settings()
	check(String(game.settings.resolution) == "1280x720" and game.language == "en", "video/language settings persist")

	if failures.is_empty():
		print("PC GAME EMPIRE BETA QA: ALL TESTS PASSED")
		quit(0)
	else:
		printerr("PC GAME EMPIRE BETA QA: ", failures.size(), " FAILURE(S)")
		quit(1)
