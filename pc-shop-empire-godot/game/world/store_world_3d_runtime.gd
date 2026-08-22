extends "res://game/world/store_world_3d.gd"

const FollowCamera = preload("res://game/world/follow_camera_3d.gd")
const ActorVisual = preload("res://game/world/stylized_actor_visual.gd")
const ShopAssets = preload("res://game/art/modular_shop_assets.gd")

var animated_monitors:Array[MeshInstance3D] = []
var animated_fans:Array[Node3D] = []
var shop_art_root:Node3D

# Runtime world layer: real physics + stable camera + genuine modular scene art.
func _build_environment() -> void:
	super._build_environment()
	_add_collision_box("ShopFloorCollision", Vector3(0,-0.15,0), Vector3(18,0.3,16))
	_add_collision_box("LabFloorCollision", Vector3(13.5,-0.15,-1.0), Vector3(9,0.3,12))
	_build_final_shop_pass()
	_build_lab_detail_pass()

func _process(delta:float) -> void:
	super._process(delta)
	_animate_shop(delta)

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

func _spawn_customer() -> void:
	customer = CustomerScript.new(); customer.name = "FirstCustomer"; customer.position = Vector3(0,0.02,6.8)
	var collision := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.radius=0.32; capsule.height=1.8; collision.shape=capsule; collision.position.y=0.9; customer.add_child(collision)
	var visual=ActorVisual.new(); visual.name="CustomerVisual"; visual.configure(Color("#277da8"),Color("#2c3440"),Color("#c78f6c")); customer.add_child(visual)
	add_child(customer)
	customer.set_route([Vector3(0,0.02,4.7),Vector3(-1.2,0.02,2.2),Vector3(0,0.02,-0.25)])

func _build_final_shop_pass() -> void:
	shop_art_root=Node3D.new(); shop_art_root.name="ModularShopArt_Final"; add_child(shop_art_root)
	# Architectural finish layer: real geometry, trims and readable floor grid.
	for x in [-7.4,-3.7,0.0,3.7,7.4]:
		_add_box("FloorInlay",Vector3(x,0.015,0),Vector3(0.025,0.025,14.8),Color("#334454"),false)
	for z in [-6.2,-3.0,0.2,3.4,6.4]:
		_add_box("FloorJoint",Vector3(0,0.018,z),Vector3(16.8,0.02,0.02),Color("#111821"),false)
	for x in [-7.2,-4.8,-2.4,0.0,2.4,4.8,7.2]:
		_add_box("WallFrame",Vector3(x,1.7,-7.72),Vector3(0.08,2.6,0.08),Color("#596673"),false)
	_add_emissive_box("EmpireSign",Vector3(0,2.72,-7.54),Vector3(7.0,0.38,0.08),Color("#ef3156"),2.7)
	_add_label("PC GAME EMPIRE",Vector3(0,2.74,-7.47),Vector3(0,180,0),36,Color.WHITE)
	# Final modular sales counter overlays the old technical shell while preserving its collider/interaction.
	var counter:Node3D=ShopAssets.build_sales_counter(); counter.position=Vector3(0,0.02,-1.70); shop_art_root.add_child(counter)
	# Dedicated modular product zones.
	var entry_shelf:Node3D=ShopAssets.build_wall_shelf("ENTRY",Color("#3bbfe8")); entry_shelf.position=Vector3(-6.65,0.02,-4.65); entry_shelf.rotation_degrees.y=90; shop_art_root.add_child(entry_shelf)
	var gaming_shelf:Node3D=ShopAssets.build_wall_shelf("GAMING",Color("#ed365b")); gaming_shelf.position=Vector3(-6.65,0.02,-1.75); gaming_shelf.rotation_degrees.y=90; shop_art_root.add_child(gaming_shelf)
	var storage_shelf:Node3D=ShopAssets.build_wall_shelf("STORAGE",Color("#9b67ee")); storage_shelf.position=Vector3(-6.65,0.02,1.10); storage_shelf.rotation_degrees.y=90; shop_art_root.add_child(storage_shelf)
	var pc_island:Node3D=ShopAssets.build_display_island(Color("#e93258"),"pc"); pc_island.position=Vector3(2.35,0.02,3.35); shop_art_root.add_child(pc_island)
	var laptop_island:Node3D=ShopAssets.build_display_island(Color("#39bfe7"),"laptop"); laptop_island.position=Vector3(-2.55,0.02,3.35); shop_art_root.add_child(laptop_island)
	var peripheral:Node3D=ShopAssets.build_peripheral_display(Color("#c84fff")); peripheral.position=Vector3(7.05,0.02,-4.0); peripheral.rotation_degrees.y=-90; shop_art_root.add_child(peripheral)
	# Branded entrance anchors make the entrance read as a designed storefront instead of a wall gap.
	for x in [-2.35,2.35]:
		var totem:Node3D=ShopAssets.build_brand_totem(Color("#ed3157")); totem.position=Vector3(x,0.02,6.82); shop_art_root.add_child(totem)
	# Seating/waiting corner.
	var chair_a:Node3D=ShopAssets.build_chair(Color("#e93258")); chair_a.position=Vector3(5.8,0.02,5.65); chair_a.rotation_degrees.y=205; shop_art_root.add_child(chair_a)
	var chair_b:Node3D=ShopAssets.build_chair(Color("#36bce6")); chair_b.position=Vector3(7.0,0.02,5.35); chair_b.rotation_degrees.y=165; shop_art_root.add_child(chair_b)
	var plant:Node3D=ShopAssets.build_plant(); plant.position=Vector3(7.9,0.02,6.25); shop_art_root.add_child(plant)
	# Monitor showroom wall uses the same premium monitor module as the counter.
	for i in range(4):
		var x=-3.9+i*2.55
		var accent:=Color("#35c3eb") if i%2==0 else Color("#ef3a60")
		var mroot:=Node3D.new(); mroot.position=Vector3(x,1.78,-7.40); shop_art_root.add_child(mroot)
		ShopAssets.build_monitor(mroot,Vector3.ZERO,accent,1.0)
		_add_box("MonitorShelf",Vector3(x,1.12,-7.43),Vector3(2.05,0.08,0.48),Color("#56616d"),false)
	# Physical store terminal receives a richer workstation cluster without changing the Area3D.
	var terminal_root:=Node3D.new(); terminal_root.name="StoreTerminal_Final"; terminal_root.position=Vector3(6.30,0.02,2.82); shop_art_root.add_child(terminal_root)
	ShopAssets.build_monitor(terminal_root,Vector3(0,1.48,-0.10),Color("#35bfe8"),0.92)
	ShopAssets.build_keyboard(terminal_root,Vector3(-0.16,1.10,0.20),Color("#35bfe8"))
	ShopAssets.build_mouse(terminal_root,Vector3(0.64,1.14,0.18),Color("#ef365b"))
	# Practical overhead strips and product highlights.
	for x in [-5.5,0.0,5.5]: _add_emissive_box("ShopLightBar",Vector3(x,3.05,-0.6),Vector3(3.6,0.05,0.16),Color("#e4f2ff"),2.15)
	_add_light(Vector3(-2.5,2.65,3.4),Color("#78d9ff"),1.35,4.7)
	_add_light(Vector3(2.4,2.65,3.4),Color("#ff6b86"),1.35,4.7)
	_register_shop_animation_nodes(shop_art_root)

func _register_shop_animation_nodes(node:Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and (String(child.name).contains("Screen") or String(child.name).contains("Glow")):
			animated_monitors.append(child)
		if child is Node3D and (String(child.name).contains("FrontFan") or String(child.name).contains("CPUFan")):
			animated_fans.append(child)
		_register_shop_animation_nodes(child)

func _animate_shop(delta:float) -> void:
	for fan in animated_fans:
		if is_instance_valid(fan): fan.rotate_z(delta*4.5)
	var pulse:=0.88+sin(Time.get_ticks_msec()*0.0022)*0.12
	for monitor in animated_monitors:
		if not is_instance_valid(monitor): continue
		var material:=monitor.material_override as StandardMaterial3D
		if material!=null and material.emission_enabled: material.emission_energy_multiplier=1.35*pulse+0.45

func _build_lab_detail_pass() -> void:
	_add_box("Pegboard",Vector3(13.4,1.75,-6.78),Vector3(6.8,2.1,0.10),Color("#25313d"),false)
	for row in range(4):
		for col in range(12): _add_box("Peg",Vector3(10.6+col*0.5,1.05+row*0.42,-6.70),Vector3(0.045,0.045,0.05),Color("#73808e"),false)
	for i in range(6):
		_add_box("ScrewdriverHandle",Vector3(11.0+i*0.55,1.75,-6.58),Vector3(0.11,0.48,0.10),Color("#d92c4d") if i%2==0 else Color("#37a9d7"),false)
		_add_box("ScrewdriverShaft",Vector3(11.0+i*0.55,1.42,-6.58),Vector3(0.035,0.32,0.035),Color("#8d99a4"),false)
	_add_box("ESDMat",Vector3(13.2,1.245,-3.70),Vector3(3.5,0.025,1.18),Color("#10232a"),false)
	for i in range(4): _add_box("PartsTray",Vector3(10.9+i*0.58,1.30,-3.32),Vector3(0.48,0.10,0.38),Color("#3c4855"),false)
	_add_box("LooseGPU",Vector3(14.6,1.36,-3.65),Vector3(1.45,0.18,0.52),Color("#202a34"),false)
	for i in range(2): _add_cylinder_prop("GPUFan",Vector3(14.25+i*0.66,1.48,-3.91),0.20,0.055,Color("#111820"))
	for z in [-0.3,1.1,2.5,3.8]:
		_add_box("LabCabinet",Vector3(17.1,0.75,z),Vector3(1.35,1.5,1.05),Color("#27333f"),true)
		for y in [0.3,0.75,1.2]: _add_box("DrawerLine",Vector3(16.40,y,z),Vector3(0.025,0.03,0.72),Color("#687583"),false)
	for x in [10.5,11.3,12.1]: _add_box("SpareBox",Vector3(x,0.35,4.15),Vector3(0.62,0.70,0.70),Color("#a02d46") if int(x*10)%2==0 else Color("#2d789d"),false)
	_add_emissive_box("LabTaskLight",Vector3(13.2,2.85,-3.7),Vector3(5.2,0.08,0.20),Color("#dcefff"),2.5)
	_add_light(Vector3(13.2,2.55,-3.7),Color("#dcefff"),2.4,5.8)
	_add_label("LABORATORIO",Vector3(13.5,2.55,-6.65),Vector3(0,180,0),30,Color("#f1f5f8"))

func _add_emissive_box(n:String,pos:Vector3,size_value:Vector3,tone:Color,energy:float) -> MeshInstance3D:
	var node:=_add_box(n,pos,size_value,Color("#121820"),false)
	var material:=_material(Color("#121820"),0.30,0.25); material.emission_enabled=true; material.emission=tone; material.emission_energy_multiplier=energy; node.material_override=material; return node

func _add_label(text_value:String,pos:Vector3,rot:Vector3,font_size:int,tone:Color) -> void:
	var label:=Label3D.new(); label.text=text_value; label.position=pos; label.rotation_degrees=rot; label.font_size=font_size; label.modulate=tone; label.outline_size=6; label.outline_modulate=Color(0,0,0,0.75); label.no_depth_test=false; add_child(label)

func _add_cylinder_prop(n:String,pos:Vector3,r:float,h:float,tone:Color) -> void:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos; node.rotation_degrees=Vector3(90,0,0)
	var mesh:=CylinderMesh.new(); mesh.top_radius=r; mesh.bottom_radius=r; mesh.height=h; node.mesh=mesh; node.material_override=_material(tone,0.42,0.18); add_child(node)
