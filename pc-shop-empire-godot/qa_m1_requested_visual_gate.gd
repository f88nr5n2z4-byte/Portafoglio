extends SceneTree

var game
var world
var out_dir:String

func _init()->void: call_deferred("run")

func run()->void:
	var packed:PackedScene=load("res://game/real_game_main.tscn")
	if packed==null: printerr("M1 REQUESTED VISUAL FAIL: main scene missing"); quit(1); return
	game=packed.instantiate(); root.add_child(game); root.size=Vector2i(1920,1080)
	out_dir=ProjectSettings.globalize_path("res://../build/requested_visuals"); DirAccess.make_dir_recursive_absolute(out_dir)
	for _i in range(28): await process_frame
	world=game.world
	if world==null or world.player==null or world.customer==null: printerr("M1 REQUESTED VISUAL FAIL: real actors missing"); quit(2); return

	await frame_at("01_protagonist_shop",Vector3(0,0.02,4.4),7.8)
	await frame_at("02_protagonist_laboratory",Vector3(13.0,0.02,-1.8),7.4)

	var waited:=0
	while not world.customer.waiting and waited<520: await physics_frame; waited+=1
	if not world.customer.waiting: printerr("M1 REQUESTED VISUAL FAIL: customer route incomplete"); quit(3); return
	await frame_at("03_customer_in_shop",Vector3(-1.2,0.02,0.65),7.2)
	await frame_at("04_physical_workbench",Vector3(13.1,0.02,-2.0),6.5)
	var visual:Node=world.player.get_node_or_null("TechnicianVisual")
	if visual!=null and visual.has_method("play_action"): visual.play_action("workbench",2.0)
	await frame_at("05_character_workbench_lab",Vector3(12.1,0.02,-2.85),5.8)

	game._handle_interaction("workbench"); await settle(8); await save_frame("06_real_workbench_ui")
	var ui=game.assembly_ui
	ui.initialize()
	for id:String in ["case_atx","mb_b850","cpu_9600x","ram_32"]: ui.install_component(id)
	await settle(8); await save_frame("07_pc_components_installed")
	ui.initialize(); ui.install_component("case_atx"); ui.install_component("mb_b850"); ui.install_component("cpu_14600kf")
	await settle(8); await save_frame("08_incompatibility_visible")
	ui.close_workbench(); await settle(5)

	world.player.global_position=Vector3(12.25,0.02,-3.05); world.player.velocity=Vector3.ZERO; world.camera.size=5.4
	if visual!=null and visual.has_method("play_action"): visual.play_action("workbench",2.0)
	await settle(18); await save_frame("09_character_bench_real_lab")

	world.player.global_position=Vector3(0.75,0.02,3.2); world.player.velocity=Vector3.ZERO
	world.customer.global_position=Vector3(-0.75,0.02,3.2); world.customer.waiting=true; world.customer.velocity=Vector3.ZERO
	world.camera.size=3.7
	if visual!=null and visual.has_method("play_action"): visual.play_action("idle",2.0)
	var customer_visual:Node=world.customer.get_node_or_null("CustomerVisual")
	if customer_visual!=null and customer_visual.has_method("play_action"): customer_visual.play_action("talk",2.0)
	await settle(24); await save_frame("10_character_mesh_closeup")

	var count:=0; var dir:=DirAccess.open(out_dir)
	if dir!=null:
		dir.list_dir_begin(); var file:=dir.get_next()
		while file!="":
			if not dir.current_is_dir() and file.ends_with(".png"): count+=1
			file=dir.get_next()
		dir.list_dir_end()
	if count!=10: printerr("M1 REQUESTED VISUAL FAIL: expected 10 PNG, got ",count); quit(4); return
	print("PC GAME EMPIRE M1 REQUESTED VISUAL GATE: PASS — 10 REAL 1920x1080 FRAMES"); quit(0)

func frame_at(name:String,position:Vector3,camera_size:float)->void:
	world.player.global_position=position; world.player.velocity=Vector3.ZERO; world.camera.size=camera_size
	await settle(22); await save_frame(name)

func settle(frames:int)->void:
	for _i in range(frames): await process_frame

func save_frame(name:String)->void:
	await process_frame
	var image:Image=root.get_texture().get_image()
	if image==null or image.is_empty() or image.get_width()!=1920 or image.get_height()!=1080:
		printerr("M1 REQUESTED VISUAL FAIL: invalid frame ",name); quit(10); return
	if image.save_png(out_dir.path_join(name+".png"))!=OK: printerr("M1 REQUESTED VISUAL FAIL: save ",name); quit(11); return
	print("M1 REQUESTED FRAME PASS: ",name," 1920x1080")
