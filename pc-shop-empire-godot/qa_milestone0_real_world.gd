extends SceneTree

var failures:Array[String] = []

func check(condition:bool,message:String) -> void:
	if condition:
		print("M0 QA PASS: ",message)
	else:
		failures.append(message)
		printerr("M0 QA FAIL: ",message)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed:PackedScene = load("res://game/real_game_main.tscn")
	check(packed != null,"real main scene loads")
	if packed == null: quit(1); return
	var game = packed.instantiate()
	root.add_child(game)
	for _i in range(8): await physics_frame
	var status:Dictionary = game.technical_status()
	check(bool(status.get("main_scene_real_time",false)),"main scene is real-time")
	check(bool(status.get("player_character_body",false)),"player is CharacterBody3D")
	check(bool(status.get("camera_real",false)),"camera is Camera3D")
	check(bool(status.get("customer_character_body",false)),"customer is CharacterBody3D")
	check(bool(status.get("shop_geometry",false)) and bool(status.get("lab_geometry",false)),"shop and lab are real geometry")
	check(not bool(status.get("world_raster_used",true)),"world raster is not used")
	check(int(status.get("interaction_count",0)) >= 5,"world contains physical interactions")
	var world = game.world
	var player:CharacterBody3D = world.player
	var start := player.global_position
	Input.action_press("move_right")
	for _i in range(45): await physics_frame
	Input.action_release("move_right")
	check(player.global_position.x > start.x + 1.0,"WASD/input moves the real player body")

	player.global_position = Vector3(-8.25,0.65,0.0)
	player.velocity = Vector3.ZERO
	Input.action_press("move_left")
	for _i in range(75): await physics_frame
	Input.action_release("move_left")
	check(player.global_position.x > -8.75,"wall collision blocks the player")

	print("M0 QA CHECKPOINT: customer walking test")
	world.customer.global_position = Vector3(0.0,0.65,1.55)
	world.customer.velocity = Vector3.ZERO
	world.customer.set_route([Vector3(0.0,0.65,-0.25)])
	var customer_start:Vector3 = world.customer.global_position
	var customer_reached := false
	for _i in range(125):
		await physics_frame
		if world.customer.waiting:
			customer_reached = true
			break
	check(world.customer.global_position.z < customer_start.z - 0.8,"customer actually walks toward counter")
	check(customer_reached,"customer reaches and waits at the counter")
	check(world.customer.global_position.z < 0.35,"customer arrived at service area")
	print("M0 QA CHECKPOINT: customer route complete at ",world.customer.global_position)

	player.global_position = Vector3(7.75,0.65,-1.9)
	player.velocity = Vector3.ZERO
	world._on_player_interact()
	await physics_frame
	check(world.lab_door_open,"lab door interaction opens physical blocker")
	Input.action_press("move_right")
	for _i in range(55): await physics_frame
	Input.action_release("move_right")
	check(player.global_position.x > 9.35,"player physically walks through opened lab doorway")
	print("M0 QA CHECKPOINT: player crossed lab doorway at ",player.global_position)

	player.global_position = Vector3(6.3,0.65,3.4)
	world._on_player_interact(); await process_frame
	check(world.last_interaction == "store_pc","physical store PC triggers Shop interaction")
	player.global_position = Vector3(13.2,0.65,-2.6)
	world._on_player_interact(); await process_frame
	check(world.last_interaction == "workbench","physical workbench triggers Assembly interaction")

	if failures.is_empty():
		print("PC GAME EMPIRE MILESTONE 0 REAL-WORLD QA: ALL TESTS PASSED")
		quit(0)
	else:
		printerr("PC GAME EMPIRE MILESTONE 0 REAL-WORLD QA: ",failures.size()," FAILURE(S)")
		quit(1)
