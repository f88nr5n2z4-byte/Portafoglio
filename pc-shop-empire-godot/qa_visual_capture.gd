extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var target := "menu"
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("capture="):
			target = String(arg).trim_prefix("capture=")
	var packed: PackedScene = load("res://beta.tscn")
	if packed == null:
		printerr("VISUAL CAPTURE: beta scene missing")
		quit(1)
		return
	var game := packed.instantiate()
	root.add_child(game)
	root.size = Vector2i(1920,1080)
	# Configure representative live game state for UI-heavy screens.
	game.set("screen",target)
	game.set("money",27540)
	game.set("reputation",82)
	game.set("level",8)
	game.set("day",34)
	game.set("hour",11.7)
	if target in ["build","diagnostics","benchmark"]:
		var all_jobs: Array = game.get("jobs")
		var chosen := 0
		for i in range(all_jobs.size()):
			var j: Dictionary = all_jobs[i]
			if target=="diagnostics" and String(j.get("type",""))=="repair":
				chosen=i
				break
			if target!="diagnostics" and String(j.get("type",""))=="build":
				chosen=i
				break
		game.set("current_job",chosen)
		game.set("job_state","working")
	if target=="shop_floor":
		game.set("player",Vector2(960,760))
	for _i in range(8):
		await process_frame
	game.queue_redraw()
	for _i in range(5):
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("VISUAL CAPTURE: viewport image empty for ",target)
		quit(2)
		return
	var out_dir := ProjectSettings.globalize_path("res://../build/screenshots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := out_dir.path_join(target+".png")
	var err := image.save_png(path)
	if err != OK:
		printerr("VISUAL CAPTURE: save failed ",err," for ",path)
		quit(3)
		return
	print("VISUAL CAPTURE PASS: ",path," ",image.get_width(),"x",image.get_height())
	game.queue_free()
	await process_frame
	quit(0)
