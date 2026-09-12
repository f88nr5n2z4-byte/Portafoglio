extends SceneTree

var failures:Array[String]=[]

func check(condition:bool,message:String)->void:
	if condition: print("M0 ART QA PASS: ",message)
	else:
		failures.append(message); printerr("M0 ART QA FAIL: ",message)

func _init()->void:
	call_deferred("_run")

func _run()->void:
	var packed:PackedScene=load("res://game/real_game_main.tscn")
	check(packed!=null,"real game main loads")
	if packed==null: quit(1); return
	var game=packed.instantiate(); root.add_child(game)
	for _i in range(20): await process_frame
	var status:Dictionary=game.technical_status()
	check(not bool(status.get("world_raster_used",true)),"world raster remains disabled")
	check(bool(status.get("modular_shop_art",false)),"modular shop art root is live")
	check(bool(status.get("modular_lab_art",false)),"modular laboratory art root is live")
	check(bool(status.get("surface_finish",false)),"surface/material finish is live")
	check(bool(status.get("occlusion_registered",false)),"camera occlusion has real registered geometry")
	check(int(status.get("ambient_customer_count",0))>=3,"three additional ambient customers are spawned")
	check(int(status.get("ambient_animation_count",0))>=4,"animated environmental props are instantiated")
	var world=game.world
	# Modular shop pass must be made from live scene geometry, not a visual reference layer.
	var terminal:=_find_named(world,"StoreTerminal_Final")
	check(terminal!=null and terminal.get_node_or_null("TerminalBody")!=null,"shop terminal has a real modular workstation body")
	check(_find_named(world,"DioramaFoundation")!=null,"real 3D diorama foundation replaces the empty world void")
	check(_find_named(world,"ShopFrontLeftCutaway")!=null,"camera-facing architecture uses a finished cutaway module")
	check(_find_named(world,"DisplayIsland_accessories")!=null,"dedicated peripheral product island is instantiated")
	check(_find_named(world,"ShopLightBar")==null,"obsolete floating shop light bars are removed")
	check(_find_named(world,"LabTaskLight")==null and _find_named(world,"TaskLightHousing")!=null,"laboratory task light is mounted in a real housing")
	check(_find_named(world,"MotherboardDetailed")!=null,"laboratory workbench has a recognisable detailed motherboard")
	check(_find_named(world,"PSUDetailed")!=null and _find_named(world,"CPUCoolerDetailed")!=null,"laboratory exposes identifiable PSU and CPU cooler props")
	check(_find_named(world,"RepairCart_Final")!=null and _find_named(world,"LabStool_Final")!=null,"used laboratory layout includes repair cart and technician stool")
	check(_find_named(world,"PartsCaddy")!=null,"workbench includes organised small-parts storage")
	check(_find_named(world,"KeyBatch_0") is MultiMeshInstance3D,"repeated keyboard keys use real MultiMesh batching")
	var lab_label:=_find_named(world,"Label_LABORATORIO") as Label3D
	check(lab_label!=null and absf(lab_label.rotation_degrees.y)<1.0,"environment signage faces the camera without mirrored text")
	var modular_counter:=_find_named(world,"SalesCounter_Final")
	var counter_top:=modular_counter.get_node_or_null("CounterTop") as MeshInstance3D if modular_counter!=null else null
	check(counter_top!=null and counter_top.mesh is ArrayMesh,"visible counter uses chamfered modular mesh geometry")
	var glass:=_find_named(world,"Glass") as MeshInstance3D
	var glass_material:=glass.material_override as StandardMaterial3D if glass!=null else null
	check(glass_material!=null and glass_material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"gaming PC glass is genuinely transparent")
	var technician=world.player.get_node_or_null("TechnicianVisual")
	check(technician!=null and technician.get_node_or_null("VisualRig")!=null,"technician uses articulated visual rig")
	check(_find_named(technician,"EyeWhite")!=null and _find_named(technician,"JacketCollar")!=null,"technician has a readable face and layered outfit")
	check(_find_named(technician,"ToolPouch")!=null and _find_named(technician,"WristTerminal")!=null,"technician uniform includes profession-specific equipment")
	var final_torso:=_find_named(technician,"Torso") as MeshInstance3D
	var final_arm:=_find_named(technician,"UpperArm") as MeshInstance3D
	check(final_torso!=null and final_torso.mesh is ArrayMesh,"technician torso uses a custom tapered character mesh")
	check(final_arm!=null and final_arm.mesh is ArrayMesh,"character limbs no longer use prototype capsule primitives")
	var first_customer_visual:Node=world.customer.get_node_or_null("CustomerVisual")
	check(first_customer_visual!=null and String(first_customer_visual.get("style_id"))=="casual","first customer has a distinct casual identity")
	game._handle_interaction("store_pc")
	check(String(technician.get("action_name"))=="computer","shop terminal triggers dedicated computer pose")
	game._close_mode()
	game._handle_interaction("workbench")
	check(String(technician.get("action_name"))=="workbench","assembly bench triggers dedicated workbench pose")
	game._close_mode()
	check(game.ambient_customers.size()>=3,"ambient NPC set exists in gameplay scene")
	for actor in game.ambient_customers:
		check(actor is CharacterBody3D,"ambient customer is CharacterBody3D: "+String(actor.name))
		check(actor.get_node_or_null("CustomerVisual/VisualRig")!=null,"ambient customer has articulated rig: "+String(actor.name))
	# Door must stay visually present and animate rather than disappear.
	var door=world.lab_door_mesh
	var start_z:float=door.position.z
	world.player.global_position=Vector3(7.8,0.02,-1.9)
	world._on_player_interact()
	await _wait_until_door_idle(world)
	check(world.lab_door_open,"door state becomes open")
	check(door.visible,"door mesh remains visible while open")
	check(absf(door.position.z-start_z)>1.2,"door visibly slides open")
	var collider_disabled:=false
	for child in world.lab_door_body.get_children():
		if child is CollisionShape3D: collider_disabled=child.disabled
	check(collider_disabled,"door collider is synchronized open")
	world._toggle_lab_door()
	await _wait_until_door_idle(world)
	check(not world.lab_door_open,"door closes again")
	check(absf(door.position.z-start_z)<0.18,"door returns to closed visual position")
	var collider_enabled:=false
	for child in world.lab_door_body.get_children():
		if child is CollisionShape3D: collider_enabled=not child.disabled
	check(collider_enabled,"door collider is synchronized closed")
	# Find a visible fan rotor and screen scan animation in the real scene.
	var rotor:=_find_named(world,"FanRotor") as Node3D
	check(rotor!=null,"visible fan rotor exists")
	if rotor!=null:
		var before_rot:=rotor.rotation.z
		for _i in range(12): await process_frame
		check(absf(rotor.rotation.z-before_rot)>0.05,"fan rotor visibly animates")
	var scan:=_find_named(world,"ScanBar") as Node3D
	check(scan!=null,"animated monitor content exists")
	if scan!=null:
		var before_y:=scan.position.y
		for _i in range(15): await process_frame
		check(absf(scan.position.y-before_y)>0.002,"monitor scan content animates")
	# Camera cutaway should activate with player behind the sales counter from camera direction.
	world.player.global_position=Vector3(0,0.02,-2.85)
	for _i in range(18): await process_frame
	check(world.camera.hidden_last_frame.size()>0,"camera cutaway detects a real occluder when needed")
	var faded_counter:=_find_named(world,"CounterBody") as GeometryInstance3D
	check(faded_counter!=null and faded_counter.transparency>0.45 and faded_counter.transparency<0.92,"occlusion uses contextual geometry fade instead of deleting the furniture")
	# Existing physical interactions remain present after art pass.
	check(world.interactions.size()>=5,"physical Area3D interactions survived art pass")
	if failures.is_empty():
		print("PC GAME EMPIRE M0 ART/RUNTIME QA: ALL TESTS PASSED"); quit(0)
	else:
		printerr("PC GAME EMPIRE M0 ART/RUNTIME QA: ",failures.size()," FAILURE(S)"); quit(1)

func _wait_until_door_idle(world_node:Node,timeout_ms:int=2000)->void:
	var deadline:=Time.get_ticks_msec()+timeout_ms
	while bool(world_node.get("door_busy")) and Time.get_ticks_msec()<deadline:
		await process_frame
	await process_frame

func _find_named(node:Node,target:String)->Node:
	if String(node.name)==target: return node
	for child in node.get_children():
		var found:=_find_named(child,target)
		if found!=null: return found
	return null
