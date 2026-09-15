extends SceneTree

func _init()->void: call_deferred("run")

func run()->void:
	var packed:PackedScene=load("res://game/real_game_main.tscn")
	if packed==null: printerr("M1 WORKBENCH VISUAL FAIL: main scene missing"); quit(1); return
	var game=packed.instantiate(); root.add_child(game); root.size=Vector2i(1920,1080)
	for _i in range(24): await process_frame
	game._handle_interaction("workbench")
	for id:String in ["case_atx","mb_b850","cpu_9600x","ram_32"]: game.assembly_ui.install_component(id)
	for _i in range(12): await process_frame
	var image:Image=root.get_texture().get_image()
	if image==null or image.is_empty() or image.get_width()!=1920 or image.get_height()!=1080:
		printerr("M1 WORKBENCH VISUAL FAIL: invalid viewport"); quit(2); return
	var out_dir:=ProjectSettings.globalize_path("res://../build/screenshots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path:=out_dir.path_join("real_workbench_ui.png")
	if image.save_png(path)!=OK: printerr("M1 WORKBENCH VISUAL FAIL: cannot save image"); quit(3); return
	print("PC GAME EMPIRE M1 WORKBENCH VISUAL CAPTURE: PASS — REAL 1920x1080 FRAME")
	quit(0)
