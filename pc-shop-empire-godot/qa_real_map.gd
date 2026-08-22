extends SceneTree

var failures:Array = []

func check(ok:bool,msg:String) -> void:
	if ok: print("REAL MAP QA PASS: ",msg)
	else:
		printerr("REAL MAP QA FAIL: ",msg)
		failures.append(msg)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed:PackedScene=load("res://beta.tscn")
	check(packed!=null,"main gameplay scene loads")
	if packed==null: quit(1); return
	var game=packed.instantiate()
	root.add_child(game)
	game.set("screen","shop_floor")
	for _i in range(5): await process_frame
	game._sync_real_room(true)
	for _i in range(3): await process_frame
	var status:Dictionary=game.real_map_status()
	check(bool(status.get("ready",false)),"shop is a structured real node world")
	check(int(status.get("props",0))>=20,"shop contains many independent prop nodes")
	check(int(status.get("collisions",0))>=8,"shop contains real collision bodies")
	check(int(status.get("interactions",0))>=5,"shop contains real interaction areas")
	check(bool(status.get("player_is_character_body",false)),"player is a CharacterBody2D")
	check(not bool(status.get("premium_raster_used_for_gameplay",true)),"explorable gameplay does not use the premium raster as map")
	var world=game.real_world
	var static_bodies:=0
	var areas:=0
	var props:=0
	for child in world.get_children():
		if child is StaticBody2D: static_bodies+=1
		elif child is Area2D: areas+=1
		elif String(child.name).begins_with("Prop_"): props+=1
	check(static_bodies>=8,"StaticBody2D collision objects exist in shop scene graph")
	check(areas>=5,"Area2D interaction objects exist in shop scene graph")
	check(props>=20,"furniture/products are separate nodes, not one backdrop")
	# Verify real movement changes the CharacterBody2D position.
	var before:Vector2=world.player_position()
	world.drive_player(Vector2.LEFT,220.0,0.20)
	var after:Vector2=world.player_position()
	check(after.distance_to(before)>1.0,"player physically moves through CharacterBody2D")
	# Verify customer exists as a physical actor.
	check(world.customer_body!=null and world.customer_body is CharacterBody2D,"customer is a real actor in the shop")
	# Force near service counter and verify interaction resolves to a real Area2D.
	world.player_body.position=Vector2(930,350)
	var near_customer:String=world.nearest_interaction(160.0)
	check(near_customer in ["counter","customer"],"customer/counter interaction is spatially resolved")
	# Enter/build lab room and validate its physical objects.
	game.set("screen","lab_floor")
	game._sync_real_room(true)
	for _i in range(3): await process_frame
	var lab_status:Dictionary=game.real_map_status()
	check(String(lab_status.get("room",""))=="lab","laboratory is a separate real room")
	check(int(lab_status.get("props",0))>=15,"laboratory contains independent props")
	check(int(lab_status.get("collisions",0))>=7,"laboratory contains real collisions")
	check(int(lab_status.get("interactions",0))>=3,"laboratory contains bench/diagnostics/door interaction areas")
	world=game.real_world
	world.player_body.position=Vector2(980,560)
	check(world.nearest_interaction(180.0)=="bench","workbench is a spatial real interaction")
	world.player_body.position=Vector2(1470,520)
	check(world.nearest_interaction(180.0)=="diagnostic","diagnostic station is a spatial real interaction")
	if failures.is_empty():
		print("PC GAME EMPIRE REAL MAP QA: ALL TESTS PASSED")
		game.queue_free(); await process_frame; quit(0)
	else:
		printerr("PC GAME EMPIRE REAL MAP QA: ",failures.size()," FAILURE(S)")
		game.queue_free(); await process_frame; quit(1)
