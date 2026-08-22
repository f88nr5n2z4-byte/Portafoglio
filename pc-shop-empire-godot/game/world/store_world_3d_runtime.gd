extends "res://game/world/store_world_3d.gd"

const FollowCamera = preload("res://game/world/follow_camera_3d.gd")
const ActorVisual = preload("res://game/world/stylized_actor_visual.gd")

# Runtime world layer: real physics + stable camera + denser genuine scene geometry.
func _build_environment() -> void:
	super._build_environment()
	_add_collision_box("ShopFloorCollision", Vector3(0,-0.15,0), Vector3(18,0.3,16))
	_add_collision_box("LabFloorCollision", Vector3(13.5,-0.15,-1.0), Vector3(9,0.3,12))
	_build_shop_detail_pass()
	_build_lab_detail_pass()

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

func _build_shop_detail_pass() -> void:
	# Real floor inlays and aisle markers.
	for x in [-7.4,-3.7,0.0,3.7,7.4]:
		_add_box("FloorInlay",Vector3(x,0.015,0),Vector3(0.025,0.025,14.8),Color("#283a4b"),false)
	for z in [-6.2,-3.0,0.2,3.4,6.4]:
		_add_box("FloorJoint",Vector3(0,0.018,z),Vector3(16.8,0.02,0.02),Color("#121923"),false)
	# Wall framing and emissive brand rails.
	for x in [-7.2,-4.8,-2.4,0.0,2.4,4.8,7.2]:
		_add_box("WallFrame",Vector3(x,1.7,-7.72),Vector3(0.08,2.6,0.08),Color("#4c5865"),false)
	_add_emissive_box("EmpireSign",Vector3(0,2.72,-7.54),Vector3(6.9,0.38,0.08),Color("#e72549"),2.8)
	_add_label("PC GAME EMPIRE",Vector3(0,2.74,-7.47),Vector3(0,180,0),36,Color.WHITE)
	# Premium monitor wall and demo towers.
	for i in range(4):
		var x=-3.9+i*2.55
		_add_monitor(Vector3(x,1.75,-7.42),Color("#33c4ed") if i%2==0 else Color("#f13d62"))
		_add_box("MonitorShelf",Vector3(x,1.12,-7.45),Vector3(2.0,0.08,0.45),Color("#45515f"),false)
	# Peripherals/display plinths.
	for x in [-6.5,6.4]:
		for z in [-4.7,-2.1,0.5]:
			_add_box("SidePlinth",Vector3(x,0.42,z),Vector3(1.6,0.84,1.05),Color("#293541"),true)
			_add_emissive_box("PlinthEdge",Vector3(x,0.86,z+0.51),Vector3(1.62,0.045,0.04),Color("#29aadd") if x<0 else Color("#dd2c4f"),1.7)
			_add_pc(Vector3(x,1.38,z),Color("#29aadd") if x<0 else Color("#dd2c4f"),2 if z>-3 else 1)
	# Front desk details: keyboard, terminal base, product bags.
	_add_box("CounterKeyboard",Vector3(0,1.26,-1.18),Vector3(0.85,0.055,0.34),Color("#111820"),false)
	_add_box("CounterScanner",Vector3(2.0,1.32,-1.44),Vector3(0.32,0.22,0.32),Color("#222d39"),false)
	_add_emissive_box("ScannerLight",Vector3(2.0,1.45,-1.27),Vector3(0.20,0.04,0.03),Color("#47e29e"),1.8)
	# Ceiling/upper light bars remain real 3D geometry, no backdrop.
	for x in [-5.5,0.0,5.5]:
		_add_emissive_box("ShopLightBar",Vector3(x,3.05,-0.6),Vector3(3.6,0.05,0.16),Color("#d9ecff"),2.1)

func _build_lab_detail_pass() -> void:
	# Tool wall / pegboard.
	_add_box("Pegboard",Vector3(13.4,1.75,-6.78),Vector3(6.8,2.1,0.10),Color("#25313d"),false)
	for row in range(4):
		for col in range(12):
			_add_box("Peg",Vector3(10.6+col*0.5,1.05+row*0.42,-6.70),Vector3(0.045,0.045,0.05),Color("#73808e"),false)
	# Hanging tools: screwdrivers, pliers, cable rolls as separate geometry.
	for i in range(6):
		_add_box("ScrewdriverHandle",Vector3(11.0+i*0.55,1.75,-6.58),Vector3(0.11,0.48,0.10),Color("#d92c4d") if i%2==0 else Color("#37a9d7"),false)
		_add_box("ScrewdriverShaft",Vector3(11.0+i*0.55,1.42,-6.58),Vector3(0.035,0.32,0.035),Color("#8d99a4"),false)
	# Workbench mat, trays and loose component shapes.
	_add_box("ESDMat",Vector3(13.2,1.245,-3.70),Vector3(3.5,0.025,1.18),Color("#10232a"),false)
	for i in range(4):
		_add_box("PartsTray",Vector3(10.9+i*0.58,1.30,-3.32),Vector3(0.48,0.10,0.38),Color("#3c4855"),false)
	_add_box("LooseGPU",Vector3(14.6,1.36,-3.65),Vector3(1.45,0.18,0.52),Color("#202a34"),false)
	for i in range(2):
		_add_cylinder_prop("GPUFan",Vector3(14.25+i*0.66,1.48,-3.91),0.20,0.055,Color("#111820"))
	# Drawers/cabinets and spare boxes.
	for z in [-0.3,1.1,2.5,3.8]:
		_add_box("LabCabinet",Vector3(17.1,0.75,z),Vector3(1.35,1.5,1.05),Color("#27333f"),true)
		for y in [0.3,0.75,1.2]:
			_add_box("DrawerLine",Vector3(16.40,y,z),Vector3(0.025,0.03,0.72),Color("#687583"),false)
	for x in [10.5,11.3,12.1]:
		_add_box("SpareBox",Vector3(x,0.35,4.15),Vector3(0.62,0.70,0.70),Color("#a02d46") if int(x*10)%2==0 else Color("#2d789d"),false)
	# Lab overhead task lights.
	_add_emissive_box("LabTaskLight",Vector3(13.2,2.85,-3.7),Vector3(5.2,0.08,0.20),Color("#dcefff"),2.5)
	_add_light(Vector3(13.2,2.55,-3.7),Color("#dcefff"),2.4,5.8)
	_add_label("LABORATORIO",Vector3(13.5,2.55,-6.65),Vector3(0,180,0),30,Color("#f1f5f8"))

func _add_emissive_box(n:String,pos:Vector3,size_value:Vector3,tone:Color,energy:float) -> MeshInstance3D:
	var node:=_add_box(n,pos,size_value,Color("#121820"),false)
	var mat:=_material(Color("#121820"),0.30,0.25); mat.emission_enabled=true; mat.emission=tone; mat.emission_energy_multiplier=energy; node.material_override=mat; return node

func _add_label(text_value:String,pos:Vector3,rot:Vector3,font_size:int,tone:Color) -> void:
	var label:=Label3D.new(); label.text=text_value; label.position=pos; label.rotation_degrees=rot; label.font_size=font_size; label.modulate=tone; label.outline_size=6; label.outline_modulate=Color(0,0,0,0.75); label.no_depth_test=false; add_child(label)

func _add_cylinder_prop(n:String,pos:Vector3,r:float,h:float,tone:Color) -> void:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos; node.rotation_degrees=Vector3(90,0,0)
	var mesh:=CylinderMesh.new(); mesh.top_radius=r; mesh.bottom_radius=r; mesh.height=h; node.mesh=mesh; node.material_override=_material(tone,0.42,0.18); add_child(node)
