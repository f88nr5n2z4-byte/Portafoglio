extends SceneTree

var game
var world
var out_dir:String

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed:PackedScene=load("res://game/real_game_main.tscn")
	if packed==null:
		printerr("M0 VISUAL GATE FAIL: real main scene missing"); quit(1); return
	game=packed.instantiate(); root.add_child(game); root.size=Vector2i(1920,1080)
	out_dir=ProjectSettings.globalize_path("res://../build/m0_visual_gate")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for _i in range(30): await process_frame
	world=game.world
	if world==null or world.player==null or world.camera==null:
		printerr("M0 VISUAL GATE FAIL: world/player/camera missing"); quit(2); return

	# 01 — storefront/entrance, real level and player.
	await _frame_at("01_ingresso",Vector3(0,0.02,5.85),14.2,22)

	# 02 — readable overall shop composition.
	await _frame_at("02_shop_overview",Vector3(0,0.02,2.2),15.0,24)

	# 03 — real sales counter and customer service area.
	await _frame_at("03_bancone",Vector3(-0.8,0.02,0.35),11.8,24)

	# 04 — PC/laptop product islands and real merchandise.
	await _frame_at("04_product_islands",Vector3(0.0,0.02,4.25),10.9,24)

	# 05 — actual input-driven walking, not a posed screenshot.
	world.player.global_position=Vector3(-4.8,0.02,4.2); world.player.velocity=Vector3.ZERO
	world.camera.size=11.4
	for _i in range(12): await process_frame
	Input.action_press("move_right")
	for _i in range(22): await physics_frame
	await _save_frame("05_player_walking")
	for _i in range(18): await physics_frame
	Input.action_release("move_right")
	for _i in range(5): await process_frame

	# 06 — wait for the main CharacterBody3D customer to physically reach the counter.
	var waited:=0
	while not world.customer.waiting and waited<520:
		await physics_frame; waited+=1
	if not world.customer.waiting:
		printerr("M0 VISUAL GATE FAIL: customer never reached counter"); quit(3); return
	world.player.global_position=Vector3(-1.4,0.02,0.55); world.player.velocity=Vector3.ZERO; world.camera.size=10.5
	for _i in range(24): await process_frame
	await _save_frame("06_customer_counter")

	# 07 — real laboratory room.
	await _frame_at("07_laboratory",Vector3(13.3,0.02,0.4),12.2,26)

	# 08 — detailed physical workbench.
	await _frame_at("08_lab_workbench",Vector3(13.2,0.02,-1.9),9.6,24)

	# 09 — door caught during its real tween animation.
	world.player.global_position=Vector3(8.0,0.02,-1.9); world.player.velocity=Vector3.ZERO; world.camera.size=9.7
	if world.lab_door_open: world._toggle_lab_door(); for _i in range(28): await process_frame
	world._toggle_lab_door()
	for _i in range(8): await process_frame
	await _save_frame("09_lab_door_opening")
	for _i in range(24): await process_frame

	# 10 — physical shop terminal.
	await _frame_at("10_shop_terminal",Vector3(5.6,0.02,3.65),9.5,24)

	# 11 — camera cutaway/occlusion in an actual occluding route.
	world.player.global_position=Vector3(0,0.02,-2.85); world.player.velocity=Vector3.ZERO; world.camera.size=10.2
	for _i in range(30): await process_frame
	if world.camera.hidden_last_frame.is_empty():
		printerr("M0 VISUAL GATE FAIL: occlusion cutaway did not activate"); quit(4); return
	await _save_frame("11_occlusion_test")

	# 12 — final broad real-time shot with shop/lab boundary and live NPCs.
	await _frame_at("12_overall_premium",Vector3(4.4,0.02,0.7),14.6,30)

	var dir:=DirAccess.open(out_dir)
	var count:=0
	if dir!=null:
		dir.list_dir_begin()
		var f:=dir.get_next()
		while f!="":
			if not dir.current_is_dir() and f.ends_with(".png"): count+=1
			f=dir.get_next()
		dir.list_dir_end()
	if count!=12:
		printerr("M0 VISUAL GATE FAIL: expected 12 PNG, got ",count); quit(5); return
	print("M0 VISUAL GATE CAPTURE: PASS — 12 REAL 1920x1080 FRAMES")
	quit(0)

func _frame_at(name:String,player_pos:Vector3,camera_size:float,settle_frames:int) -> void:
	world.player.global_position=player_pos; world.player.velocity=Vector3.ZERO; world.camera.size=camera_size
	for _i in range(settle_frames): await process_frame
	await _save_frame(name)

func _save_frame(name:String) -> void:
	await process_frame
	var image:Image=root.get_texture().get_image()
	if image==null or image.is_empty():
		printerr("M0 VISUAL GATE FAIL: empty viewport ",name); quit(10); return
	if image.get_width()!=1920 or image.get_height()!=1080:
		printerr("M0 VISUAL GATE FAIL: wrong resolution ",name," ",image.get_width(),"x",image.get_height()); quit(11); return
	var path:=out_dir.path_join(name+".png")
	var err:=image.save_png(path)
	if err!=OK:
		printerr("M0 VISUAL GATE FAIL: save ",path," code=",err); quit(12); return
	print("M0 VISUAL FRAME PASS: ",name," 1920x1080")
