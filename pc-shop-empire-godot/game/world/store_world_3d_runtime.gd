extends "res://game/world/store_world_3d.gd"

const FollowCamera = preload("res://game/world/follow_camera_3d.gd")
const ActorVisual = preload("res://game/world/stylized_actor_visual.gd")
const ShopAssets = preload("res://game/art/modular_shop_assets.gd")
const LabAssets = preload("res://game/art/modular_lab_assets.gd")
const SurfacePass = preload("res://game/art/world_surface_pass.gd")
const WorldAudio = preload("res://game/audio/world_audio.gd")

var animated_monitors:Array[MeshInstance3D] = []
var animated_fans:Array[Node3D] = []
var shop_art_root:Node3D
var lab_art_root:Node3D
var surface_root:Node3D
var occlusion_nodes:Array[Dictionary] = []
var interaction_beacons:Dictionary = {}
var door_busy:=false
var door_audio:AudioStreamPlayer3D
var interact_audio:AudioStreamPlayer3D

# Runtime world layer: real physics + stable camera + genuine modular scene art.
func _build_environment() -> void:
	super._build_environment()
	_add_collision_box("ShopFloorCollision", Vector3(0,-0.15,0), Vector3(18,0.3,16))
	_add_collision_box("LabFloorCollision", Vector3(13.5,-0.15,-1.0), Vector3(9,0.3,12))
	surface_root=SurfacePass.build(); add_child(surface_root)
	_build_final_shop_pass()
	_build_final_lab_pass()
	_build_interaction_polish()
	_build_world_audio()

func _process(delta:float) -> void:
	super._process(delta)
	_animate_world(delta)
	_update_interaction_polish()

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.name = "PlayerCharacter"
	player.position = Vector3(0,0.02,5.7)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.33; capsule.height = 1.8
	collision.shape = capsule; collision.position.y = 0.9
	player.add_child(collision)
	var visual = ActorVisual.new(); visual.name="TechnicianVisual"; visual.configure(Color("#c62543"),Color("#202a36"),Color("#d5a17e")); player.add_child(visual)
	add_child(player)
	player.interaction_requested.connect(_on_player_interact)
	camera = FollowCamera.new()
	camera.name = "IsometricFollowCamera"
	add_child(camera)
	camera.set_target(player)
	for item in occlusion_nodes:
		camera.register_occludable(item.get("node"),float(item.get("radius",0.8)),float(item.get("height",0.7)))

func _spawn_customer() -> void:
	customer = CustomerScript.new(); customer.name = "FirstCustomer"; customer.position = Vector3(0,0.02,6.8)
	var collision := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.radius=0.32; capsule.height=1.8; collision.shape=capsule; collision.position.y=0.9; customer.add_child(collision)
	var visual=ActorVisual.new(); visual.name="CustomerVisual"; visual.configure(Color("#277da8"),Color("#2c3440"),Color("#c78f6c")); customer.add_child(visual)
	add_child(customer)
	customer.set_route([Vector3(0,0.02,4.7),Vector3(-1.2,0.02,2.2),Vector3(0,0.02,-0.25)])

func _mark_occludable(node:Node3D,radius:float,height:float=0.7) -> void:
	if node==null: return
	occlusion_nodes.append({"node":node,"radius":radius,"height":height})
	if camera!=null and camera.has_method("register_occludable"): camera.register_occludable(node,radius,height)

func _build_final_shop_pass() -> void:
	shop_art_root=Node3D.new(); shop_art_root.name="ModularShopArt_Final"; add_child(shop_art_root)
	for x in [-7.4,-3.7,0.0,3.7,7.4]: _add_box("FloorInlay",Vector3(x,0.015,0),Vector3(0.025,0.025,14.8),Color("#334454"),false)
	for z in [-6.2,-3.0,0.2,3.4,6.4]: _add_box("FloorJoint",Vector3(0,0.018,z),Vector3(16.8,0.02,0.02),Color("#111821"),false)
	for x in [-7.2,-4.8,-2.4,0.0,2.4,4.8,7.2]: _add_box("WallFrame",Vector3(x,1.7,-7.72),Vector3(0.08,2.6,0.08),Color("#596673"),false)
	_add_emissive_box("EmpireSign",Vector3(0,2.72,-7.54),Vector3(7.0,0.38,0.08),Color("#ef3156"),1.35)
	_add_label("PC GAME EMPIRE",Vector3(0,2.74,-7.47),Vector3.ZERO,36,Color.WHITE)
	var counter:Node3D=ShopAssets.build_sales_counter(); counter.position=Vector3(0,0.02,-1.70); shop_art_root.add_child(counter); _mark_occludable(counter,1.35,0.85)
	var entry_shelf:Node3D=ShopAssets.build_wall_shelf("CPU & GPU",Color("#3bbfe8")); entry_shelf.position=Vector3(-6.65,0.02,-4.65); entry_shelf.rotation_degrees.y=90; shop_art_root.add_child(entry_shelf); _mark_occludable(entry_shelf,1.05,1.2)
	var gaming_shelf:Node3D=ShopAssets.build_wall_shelf("MEMORY",Color("#ed365b")); gaming_shelf.position=Vector3(-6.65,0.02,-1.75); gaming_shelf.rotation_degrees.y=90; shop_art_root.add_child(gaming_shelf); _mark_occludable(gaming_shelf,1.05,1.2)
	var storage_shelf:Node3D=ShopAssets.build_wall_shelf("STORAGE",Color("#9b67ee")); storage_shelf.position=Vector3(-6.65,0.02,1.10); storage_shelf.rotation_degrees.y=90; shop_art_root.add_child(storage_shelf); _mark_occludable(storage_shelf,1.05,1.2)
	var pc_island:Node3D=ShopAssets.build_display_island(Color("#e93258"),"pc"); pc_island.position=Vector3(2.35,0.02,3.35); shop_art_root.add_child(pc_island); _mark_occludable(pc_island,1.28,0.7)
	var laptop_island:Node3D=ShopAssets.build_display_island(Color("#39bfe7"),"laptop"); laptop_island.position=Vector3(-2.55,0.02,3.35); shop_art_root.add_child(laptop_island); _mark_occludable(laptop_island,1.20,0.65)
	var accessory_island:Node3D=ShopAssets.build_display_island(Color("#a861ef"),"accessories"); accessory_island.position=Vector3(-6.45,0.02,4.70); accessory_island.rotation_degrees.y=90; shop_art_root.add_child(accessory_island); _mark_occludable(accessory_island,1.18,0.68)
	var peripheral:Node3D=ShopAssets.build_peripheral_display(Color("#c84fff")); peripheral.position=Vector3(7.05,0.02,-4.0); peripheral.rotation_degrees.y=-90; shop_art_root.add_child(peripheral); _mark_occludable(peripheral,1.10,1.25)
	var build_totem:Node3D=ShopAssets.build_brand_totem(Color("#ed3157"),"BUILD"); build_totem.position=Vector3(-2.35,0.02,6.82); shop_art_root.add_child(build_totem); _mark_occludable(build_totem,0.55,1.2)
	var play_totem:Node3D=ShopAssets.build_brand_totem(Color("#39c3e9"),"PLAY"); play_totem.position=Vector3(2.35,0.02,6.82); shop_art_root.add_child(play_totem); _mark_occludable(play_totem,0.55,1.2)
	var entry_mat:Node3D=ShopAssets.build_entry_mat(); entry_mat.position=Vector3(0,0.035,5.62); shop_art_root.add_child(entry_mat)
	var consultation:Node3D=ShopAssets.build_consultation_table(); consultation.position=Vector3(5.55,0.02,0.10); consultation.rotation_degrees.y=90; shop_art_root.add_child(consultation); _mark_occludable(consultation,0.92,0.58)
	var chair_a:Node3D=ShopAssets.build_chair(Color("#e93258")); chair_a.position=Vector3(5.55,0.02,1.10); chair_a.rotation_degrees.y=180; shop_art_root.add_child(chair_a)
	var chair_b:Node3D=ShopAssets.build_chair(Color("#36bce6")); chair_b.position=Vector3(5.55,0.02,-0.90); chair_b.rotation_degrees.y=0; shop_art_root.add_child(chair_b)
	var plant:Node3D=ShopAssets.build_plant(); plant.position=Vector3(7.9,0.02,6.25); shop_art_root.add_child(plant)
	for i in range(4):
		var x=-3.9+i*2.55
		var accent:=Color("#35c3eb") if i%2==0 else Color("#ef3a60")
		var mroot:=Node3D.new(); mroot.position=Vector3(x,1.78,-7.40); shop_art_root.add_child(mroot)
		ShopAssets.build_monitor(mroot,Vector3.ZERO,accent,1.0)
		_add_box("MonitorShelf",Vector3(x,1.12,-7.43),Vector3(2.05,0.08,0.48),Color("#56616d"),false)
	var category_labels:PackedStringArray=["CREATOR","GAMING","PRO","ULTRAWIDE"]
	for i in range(category_labels.size()): _add_label(category_labels[i],Vector3(-3.9+i*2.55,2.29,-7.42),Vector3.ZERO,22,Color("#d9e4ea"))
	var terminal_root:Node3D=ShopAssets.build_shop_terminal(Color("#35bfe8")); terminal_root.position=Vector3(6.30,0.02,2.82); shop_art_root.add_child(terminal_root)
	_mark_occludable(terminal_root,0.82,0.9)
	# Compact practicals replace the old long floating emissive rods.
	for fixture_data in [[Vector3(-4.8,2.55,-7.42),Color("#74d7f4")],[Vector3(4.8,2.55,-7.42),Color("#f05b78")]]:
		var fixture:Node3D=ShopAssets.build_track_spot(fixture_data[1]); fixture.position=fixture_data[0]; fixture.rotation_degrees.x=90; shop_art_root.add_child(fixture)
	_add_light(Vector3(-2.5,2.65,3.4),Color("#78d9ff"),0.72,4.4)
	_add_light(Vector3(2.4,2.65,3.4),Color("#ff6b86"),0.70,4.4)
	_register_animation_nodes(shop_art_root)

func _build_final_lab_pass() -> void:
	lab_art_root=Node3D.new(); lab_art_root.name="ModularLabArt_Final"; add_child(lab_art_root)
	var tools:Node3D=LabAssets.build_tool_wall(); tools.position=Vector3(13.35,0.12,-6.68); lab_art_root.add_child(tools); _mark_occludable(tools,1.45,1.3)
	var bench:Node3D=LabAssets.build_workbench(); bench.position=Vector3(13.2,0.02,-3.70); lab_art_root.add_child(bench); _mark_occludable(bench,1.55,0.8)
	var tray:Node3D=LabAssets.build_component_tray(); tray.position=Vector3(13.85,1.32,-3.56); lab_art_root.add_child(tray)
	var open_pc:Node3D=LabAssets.build_open_pc(); open_pc.position=Vector3(11.85,1.78,-3.78); open_pc.rotation_degrees.y=8; lab_art_root.add_child(open_pc)
	var diag:Node3D=LabAssets.build_diagnostics_station(); diag.position=Vector3(15.8,0.02,1.50); lab_art_root.add_child(diag); _mark_occludable(diag,0.95,0.85)
	var storage:Node3D=LabAssets.build_storage_shelf(); storage.position=Vector3(10.55,0.02,3.95); storage.rotation_degrees.y=180; lab_art_root.add_child(storage); _mark_occludable(storage,1.15,1.35)
	var repair_cart:Node3D=LabAssets.build_repair_cart(); repair_cart.position=Vector3(15.35,0.02,-4.72); repair_cart.rotation_degrees.y=-8; lab_art_root.add_child(repair_cart); _mark_occludable(repair_cart,0.78,0.8)
	var stool:Node3D=LabAssets.build_lab_stool(Color("#38bfe8")); stool.position=Vector3(10.55,0.02,-3.05); lab_art_root.add_child(stool)
	for index in range(3):
		var accent:=Color("#e93a5d") if index%2==0 else Color("#38bfe8")
		var cabinet:Node3D=LabAssets.build_lab_cabinet(accent); cabinet.position=Vector3(17.08,0.02,-0.25+index*1.75); cabinet.rotation_degrees.y=-90; lab_art_root.add_child(cabinet); _mark_occludable(cabinet,0.72,0.9)
	var parts_table:=Node3D.new(); parts_table.name="SparePartsTable_Final"; parts_table.position=Vector3(15.3,0.02,3.65); lab_art_root.add_child(parts_table); _mark_occludable(parts_table,1.0,0.55)
	ShopAssets.box(parts_table,"TableBase",Vector3(0,0.42,0),Vector3(2.6,0.82,1.25),ShopAssets.mat(Color("#26313c"),0.34,0.52))
	ShopAssets.box(parts_table,"TableTop",Vector3(0,0.88,0),Vector3(2.76,0.10,1.38),ShopAssets.mat(Color("#65717c"),0.22,0.72))
	for i in range(3): ShopAssets.build_product_box(parts_table,Vector3(-0.78+i*0.68,1.15,-0.18),Vector3(0.48,0.44,0.48),Color("#d63a58") if i%2==0 else Color("#337fa0"),i)
	for i in range(3):
		var fan:=ShopAssets.cyl(parts_table,"SpareFan",Vector3(-0.55+i*0.55,1.08,0.38),0.18,0.055,ShopAssets.mat(Color("#111820"),0.28,0.20,Color("#9d61ef") if i==1 else Color("#39bfe7"),1.1),Vector3(90,0,0)); animated_fans.append(fan)
	_add_light(Vector3(13.2,2.50,-3.7),Color("#dff2ff"),1.32,5.5)
	_add_light(Vector3(10.8,2.1,2.8),Color("#55c8f0"),0.85,3.8)
	_add_light(Vector3(16.6,2.0,2.3),Color("#f04466"),0.75,3.6)
	_add_label("LABORATORIO",Vector3(13.5,2.58,-6.58),Vector3.ZERO,30,Color("#f1f5f8"))
	_add_label("ASSEMBLY  •  REPAIR  •  DIAGNOSTICS",Vector3(13.5,2.30,-6.57),Vector3.ZERO,17,Color("#7edcf4"))
	_register_animation_nodes(lab_art_root)

func _build_interaction_polish() -> void:
	for area in interactions:
		if area==null: continue
		var ring:=MeshInstance3D.new(); ring.name="InteractionRing_"+String(area.interaction_id); ring.position=Vector3(area.position.x,0.035,area.position.z); ring.rotation_degrees.x=90
		var mesh:=TorusMesh.new(); mesh.inner_radius=0.34; mesh.outer_radius=0.43; mesh.rings=24; mesh.ring_segments=12; ring.mesh=mesh
		var accent:=Color("#45c8ef") if String(area.interaction_id) in ["store_pc","diagnostics"] else Color("#ef3b60")
		var material:=StandardMaterial3D.new(); material.albedo_color=Color(accent.r,accent.g,accent.b,0.72); material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; material.emission_enabled=true; material.emission=accent; material.emission_energy_multiplier=1.3; ring.material_override=material; ring.visible=false; add_child(ring)
		interaction_beacons[String(area.interaction_id)]=ring

func _update_interaction_polish() -> void:
	if player==null: return
	var nearest:=_nearest_interaction(2.2)
	for id in interaction_beacons.keys():
		var ring:MeshInstance3D=interaction_beacons[id]
		ring.visible=nearest!=null and String(nearest.interaction_id)==String(id)
		if ring.visible:
			var pulse:=1.0+sin(Time.get_ticks_msec()*0.006)*0.08
			ring.scale=Vector3(pulse,pulse,pulse)

func _build_world_audio() -> void:
	door_audio=AudioStreamPlayer3D.new(); door_audio.name="DoorAudio"; door_audio.position=Vector3(9.0,1.2,-1.9); door_audio.stream=WorldAudio.door_stream(); door_audio.unit_size=6.0; add_child(door_audio)
	interact_audio=AudioStreamPlayer3D.new(); interact_audio.name="InteractionAudio"; interact_audio.stream=WorldAudio.interact_stream(); interact_audio.unit_size=5.0; add_child(interact_audio)

func _on_player_interact() -> void:
	var before:=last_interaction
	super._on_player_interact()
	if last_interaction!="" and last_interaction!=before and interact_audio!=null:
		interact_audio.global_position=player.global_position; interact_audio.play()
	var visual:=player.get_node_or_null("TechnicianVisual")
	if visual!=null and visual.has_method("play_action"): visual.play_action("interact")

func _toggle_lab_door() -> void:
	if door_busy or lab_door_mesh==null or lab_door_body==null: return
	door_busy=true
	lab_door_open=not lab_door_open
	if door_audio!=null: door_audio.play()
	var closed_z:=-1.9
	var open_z:=-4.15
	var tween:=create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if lab_door_open:
		for child in lab_door_body.get_children():
			if child is CollisionShape3D: child.disabled=true
		tween.tween_property(lab_door_mesh,"position:z",open_z,0.34)
	else:
		tween.tween_property(lab_door_mesh,"position:z",closed_z,0.34)
		tween.tween_callback(func():
			for child in lab_door_body.get_children():
				if child is CollisionShape3D: child.disabled=false
		)
	tween.finished.connect(func(): door_busy=false)
	print("REAL DOOR STATE: ","OPEN" if lab_door_open else "CLOSED")

func _register_animation_nodes(node:Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and (String(child.name).contains("Screen") or String(child.name).contains("Glow") or String(child.name).contains("Status")):
			animated_monitors.append(child)
		if child is Node3D and (String(child.name).contains("FrontFan") or String(child.name).contains("CPUFan") or String(child.name).contains("SpareFan")):
			animated_fans.append(child)
		_register_animation_nodes(child)

func _animate_world(delta:float) -> void:
	for fan in animated_fans:
		if is_instance_valid(fan): fan.rotate_z(delta*4.5)
	var pulse:=0.88+sin(Time.get_ticks_msec()*0.0022)*0.12
	for monitor in animated_monitors:
		if not is_instance_valid(monitor): continue
		var material:=monitor.material_override as StandardMaterial3D
		if material!=null and material.emission_enabled: material.emission_energy_multiplier=1.35*pulse+0.45

func _add_emissive_box(n:String,pos:Vector3,size_value:Vector3,tone:Color,energy:float) -> MeshInstance3D:
	var node:=_add_box(n,pos,size_value,Color("#121820"),false)
	var material:=_material(Color("#121820"),0.30,0.25); material.emission_enabled=true; material.emission=tone; material.emission_energy_multiplier=energy; node.material_override=material; return node

func _add_label(text_value:String,pos:Vector3,rot:Vector3,font_size:int,tone:Color) -> void:
	var label:=Label3D.new(); label.name="Label_"+text_value.replace(" ","_"); label.text=text_value; label.position=pos; label.rotation_degrees=rot; label.font_size=font_size; label.modulate=tone; label.outline_size=6; label.outline_modulate=Color(0,0,0,0.75); label.no_depth_test=false; add_child(label)
