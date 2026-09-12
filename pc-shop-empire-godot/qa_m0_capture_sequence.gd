extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed:PackedScene = load("res://game/real_game_main.tscn")
	if packed == null:
		printerr("M0 CAPTURE FAIL: main scene missing"); quit(1); return
	var game = packed.instantiate(); root.add_child(game); root.size=Vector2i(1920,1080)
	for _i in range(20): await process_frame
	await _save_frame("01_spawn")
	Input.action_press("move_right")
	for _i in range(35): await physics_frame
	Input.action_release("move_right")
	for _i in range(4): await process_frame
	await _save_frame("02_walk_shop")
	Input.action_press("move_up")
	for _i in range(45): await physics_frame
	Input.action_release("move_up")
	for _i in range(4): await process_frame
	await _save_frame("03_approach_counter")
	game.world.player.global_position=Vector3(7.75,0.65,-1.9)
	game.world._on_player_interact()
	for _i in range(5): await process_frame
	Input.action_press("move_right")
	for _i in range(42): await physics_frame
	Input.action_release("move_right")
	for _i in range(5): await process_frame
	await _save_frame("04_inside_lab")
	print("M0 REAL-TIME SEQUENCE CAPTURE: PASS")
	quit(0)

func _save_frame(name:String) -> void:
	await process_frame
	var image:Image=root.get_texture().get_image()
	if image==null or image.is_empty():
		printerr("M0 CAPTURE FAIL: empty viewport ",name); quit(2); return
	var out_dir:=ProjectSettings.globalize_path("res://../build/m0_frames")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path:=out_dir.path_join(name+".png")
	var err:=image.save_png(path)
	if err!=OK:
		printerr("M0 CAPTURE FAIL: ",path," code=",err); quit(3); return
	print("M0 FRAME PASS: ",name," ",image.get_width(),"x",image.get_height())
