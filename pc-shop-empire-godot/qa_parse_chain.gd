extends SceneTree

func _init() -> void:
	var paths := [
		"res://beta.gd",
		"res://beta_runtime.gd",
		"res://beta_polish.gd",
		"res://beta_release.gd",
		"res://beta_final.gd",
		"res://beta_commercial.gd",
		"res://beta_ship.gd",
		"res://beta_hotfix.gd",
		"res://visual_upgrade.gd",
		"res://visual_upgrade_real.gd",
		"res://milestone_a.gd",
		"res://qa_game.gd"
	]
	var failed := false
	for path in paths:
		print("PARSE CHECK START: ", path)
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			printerr("PARSE CHECK FAIL: ", path)
			failed = true
			break
		print("PARSE CHECK PASS: ", path)
	if failed:
		quit(1)
	else:
		print("PARSE CHAIN: ALL SCRIPTS INSTANTIABLE")
		quit(0)
