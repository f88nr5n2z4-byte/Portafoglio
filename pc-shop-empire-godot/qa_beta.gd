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
	check(game_script != null, "beta runtime script loads")
	if game_script == null:
		quit(1)
		return
	var game = game_script.new()
	game._load_data()
	check(game.components.size() >= 15, "hardware catalog loaded")
	check(game.jobs.size() >= 6, "job catalog loaded")
	game._new_game()
	check(game.money == 2000, "new game starts with 2000 euro")
	check(game.current_job == 0, "first job is offered")
	game.job_state = "accepted"
	var build_ids := {
		"CPU":"cpu_9600x",
		"Motherboard":"mb_b850",
		"RAM":"ram_32",
		"GPU":"gpu_5060",
		"Storage":"ssd_1tb",
		"PSU":"psu_750",
		"Case":"case_atx",
		"Cooling":"cooler_air"
	}
	for cat in build_ids:
		var id: String = build_ids[cat]
		game.inventory[id] = 1
		var c: Dictionary = game._component(id)
		check(not c.is_empty(), "component exists: " + id)
		var reason: String = game._compatibility_reason(c)
		check(reason == "", "compatible component accepted: " + id)
		game._install_component(c)
	check(game._build_ready(), "first PC build becomes complete")
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
	check(game.money == saved_money, "load restores money")
	game.current_job = 1
	game.job_state = "accepted"
	game.diagnostics_done = ["Power","POST"]
	check(game._diagnosis_revealed(), "repair diagnosis requires tests and reveals fault")
	game.build_slots.clear()
	game.inventory["psu_750"] = 1
	game._install_component(game._component("psu_750"))
	check(game._build_ready(), "repair becomes complete after correct replacement")
	var incompatible_cpu: Dictionary = game._component("cpu_14600kf")
	game.build_slots = {"Motherboard":"mb_b850"}
	check(game._compatibility_reason(incompatible_cpu) != "", "socket mismatch is rejected")
	game.settings.resolution = "1280x720"
	game.settings.language = "en"
	game.language = "en"
	game._save_settings()
	check(FileAccess.file_exists(game.SETTINGS_PATH), "settings file created")
	# Release-only systems.
	game.money = 5000
	game.upgrades.Showroom = 1
	check(int(game.upgrades.Showroom) == 1, "shop upgrade state is writable")
	game.damaged_inventory["cpu_14600kf"] = 1
	check(game._compatibility_reason(incompatible_cpu).contains("guasto"), "damaged used component is rejected")
	if failures.is_empty():
		print("PC GAME EMPIRE BETA QA: ALL TESTS PASSED")
		quit(0)
	else:
		printerr("PC GAME EMPIRE BETA QA: ", failures.size(), " FAILURE(S)")
		quit(1)
