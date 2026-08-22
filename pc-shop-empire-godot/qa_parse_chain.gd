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
		"res://milestone_a_complete.gd",
		"res://milestone_a_final.gd",
		"res://maximum_quality_pass.gd",
		"res://maximum_quality_final.gd",
		"res://real_world_prop.gd",
		"res://real_world_actor.gd",
		"res://real_world_map.gd",
		"res://real_map_pass.gd",
		"res://game/world/player_3d.gd",
		"res://game/world/customer_3d.gd",
		"res://game/world/interactable_3d.gd",
		"res://game/world/store_world_3d.gd",
		"res://game/real_game_main.gd",
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
