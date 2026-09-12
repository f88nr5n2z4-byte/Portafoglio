extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _set_build_state(game,target:String) -> void:
	game.set("screen","build")
	game.set("current_job",0)
	game.set("job_state","working")
	game.set("case_panel_open",true)
	game.set("thermal_paste_applied",false)
	game.set("cables_connected",false)
	game.set("build_slots",{})
	var slots:Dictionary = {}
	match target:
		"build_empty":
			slots={"Case":"case_atx"}
		"build_entry":
			slots={"Case":"case_atx","Motherboard":"mb_b550","CPU":"cpu_5600","RAM":"ram_16_ddr4","GPU":"gpu_5060","Storage":"ssd_1tb","PSU":"psu_750","Cooling":"cooler_air"}
		"build_mid":
			slots={"Case":"case_lancool","Motherboard":"mb_b850","CPU":"cpu_9600x","RAM":"ram_32","GPU":"gpu_5070_palit","Storage":"ssd_2tb","PSU":"psu_850","Cooling":"cooler_air","Fans":"fan_120"}
		"build_high":
			slots={"Case":"case_atx","Motherboard":"mb_b850_aorus","CPU":"cpu_9800x3d","RAM":"ram_64","GPU":"gpu_5080","Storage":"ssd_2tb","PSU":"psu_1000","Cooling":"cooler_aio","Fans":"fan_120"}
		"build_cpu_ram":
			slots={"Case":"case_atx","Motherboard":"mb_b850","CPU":"cpu_9600x","RAM":"ram_32"}
		"build_gpu":
			slots={"Case":"case_lancool","Motherboard":"mb_b850","CPU":"cpu_9600x","RAM":"ram_32","GPU":"gpu_5070_msi","PSU":"psu_850"}
		"build_cooling":
			slots={"Case":"case_atx","Motherboard":"mb_b850_aorus","CPU":"cpu_9800x3d","RAM":"ram_64","Cooling":"cooler_aio","Fans":"fan_120"}
		"build_complete":
			slots={"Case":"case_atx","Motherboard":"mb_b850_aorus","CPU":"cpu_9800x3d","RAM":"ram_64","GPU":"gpu_5080","Storage":"ssd_2tb","PSU":"psu_1000","Cooling":"cooler_aio","Fans":"fan_120"}
			game.set("case_panel_open",false)
			game.set("thermal_paste_applied",true)
			game.set("cables_connected",true)
	game.set("build_slots",slots)
	if target in ["build_entry","build_mid","build_high","build_gpu","build_cooling"]:
		game.set("thermal_paste_applied",true)
	if target in ["build_entry","build_mid","build_high"]:
		game.set("cables_connected",true)
	game.set("inventory",{"gpu_5060":1,"gpu_5070_msi":1,"ram_32":1,"ssd_2tb":1,"cooler_aio":1,"fan_120":1})

func _capture() -> void:
	var target := "menu"
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("capture="):
			target = String(arg).trim_prefix("capture=")
	var packed: PackedScene = load("res://beta.tscn")
	if packed == null:
		printerr("VISUAL CAPTURE: beta scene missing")
		quit(1); return
	var game := packed.instantiate()
	root.add_child(game)
	root.size = Vector2i(1920,1080)
	if target.begins_with("build_"):
		_set_build_state(game,target)
	else:
		var actual_screen := target
		if target=="shop_walk": actual_screen="shop_floor"
		if target=="lab_walk": actual_screen="lab_floor"
		game.set("screen",actual_screen)
		game.set("money",27540); game.set("reputation",82); game.set("level",8); game.set("day",34); game.set("hour",11.7)
		if actual_screen in ["build","diagnostics","benchmark"]:
			var all_jobs: Array = game.get("jobs"); var chosen := 0
			for i in range(all_jobs.size()):
				var j: Dictionary = all_jobs[i]
				if actual_screen=="diagnostics" and String(j.get("type",""))=="repair": chosen=i; break
				if actual_screen!="diagnostics" and String(j.get("type",""))=="build": chosen=i; break
			game.set("current_job",chosen); game.set("job_state","working")
		if actual_screen=="shop_floor":
			game.set("current_job",0); game.set("job_state","offered"); game.set("player",Vector2(960,760) if target=="shop_floor" else Vector2(1240,660))
		if actual_screen=="lab_floor":
			game.set("current_job",0); game.set("job_state","working"); game.set("lab_player",Vector2(930,800) if target=="lab_floor" else Vector2(720,650))
	for _i in range(12): await process_frame
	game.queue_redraw()
	for _i in range(8): await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("VISUAL CAPTURE: viewport image empty for ",target); quit(2); return
	var out_dir := ProjectSettings.globalize_path("res://../build/screenshots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := out_dir.path_join(target+".png")
	var err := image.save_png(path)
	if err != OK:
		printerr("VISUAL CAPTURE: save failed ",err," for ",path); quit(3); return
	print("VISUAL CAPTURE PASS: ",path," ",image.get_width(),"x",image.get_height())
	game.queue_free(); await process_frame; quit(0)
