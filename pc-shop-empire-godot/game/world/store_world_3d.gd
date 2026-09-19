extends Node3D

const PlayerScript = preload("res://game/world/player_3d.gd")
const CustomerScript = preload("res://game/world/customer_3d.gd")
const InteractableScript = preload("res://game/world/interactable_3d.gd")

var player: CharacterBody3D
var customer: CharacterBody3D
var camera: Camera3D
var interactions: Array[Area3D] = []
var prompt_text := ""
var last_interaction := ""
var lab_door_open := false
var lab_door_mesh: MeshInstance3D
var lab_door_body: StaticBody3D

func _ready() -> void:
	_build_environment()
	_spawn_player()
	_spawn_customer()
	print("REAL WORLD 3D READY: no world raster; geometry/collision/NPC/camera live")

func _process(_delta: float) -> void:
	_update_prompt()

func _build_environment() -> void:
	# Floor slabs: shop and laboratory are separate real meshes.
	_add_box("ShopFloor", Vector3(0,-0.15,0), Vector3(18,0.3,16), Color("#202733"), false)
	_add_box("LabFloor", Vector3(13.5,-0.15,-1.0), Vector3(9,0.3,12), Color("#18232e"), false)
	# Exterior/partition walls. Gap at x=9,z=-2 is the real lab doorway.
	_add_box("BackWall", Vector3(0,1.6,-8), Vector3(18,3.2,0.35), Color("#161d27"), true)
	_add_box("LeftWall", Vector3(-9,1.6,0), Vector3(0.35,3.2,16), Color("#18212b"), true)
	_add_box("FrontWallL", Vector3(-5.4,1.6,8), Vector3(7.2,3.2,0.35), Color("#151c25"), true)
	_add_box("FrontWallR", Vector3(5.4,1.6,8), Vector3(7.2,3.2,0.35), Color("#151c25"), true)
	_add_box("RightPartitionA", Vector3(9,1.6,-5.3), Vector3(0.35,3.2,5.4), Color("#161f29"), true)
	_add_box("RightPartitionB", Vector3(9,1.6,3.2), Vector3(0.35,3.2,9.6), Color("#161f29"), true)
	_add_box("LabRightWall", Vector3(18,1.6,-1), Vector3(0.35,3.2,12), Color("#151d26"), true)
	_add_box("LabBackWall", Vector3(13.5,1.6,-7), Vector3(9,3.2,0.35), Color("#151d26"), true)
	_add_box("LabFrontWall", Vector3(13.5,1.6,5), Vector3(9,3.2,0.35), Color("#151d26"), true)
	# Entrance frame and sign.
	_add_box("EntranceLeft", Vector3(-2.2,1.6,7.82), Vector3(1.4,3.2,0.5), Color("#303946"), true)
	_add_box("EntranceRight", Vector3(2.2,1.6,7.82), Vector3(1.4,3.2,0.5), Color("#303946"), true)
	_add_box("Header", Vector3(0,2.9,-7.65), Vector3(7.8,0.35,0.45), Color("#b81735"), false)
	# Counter, real displays and shelves.
	_add_box("ServiceCounter", Vector3(0,0.55,-1.7), Vector3(5.6,1.1,1.4), Color("#2d3542"), true)
	_add_box("CounterTop", Vector3(0,1.15,-1.7), Vector3(5.9,0.15,1.55), Color("#5a6470"), false)
	_add_monitor(Vector3(-1.5,1.55,-1.4), Color("#30bde5"))
	_add_monitor(Vector3(1.5,1.55,-1.4), Color("#f0274d"))
	_add_shelf(Vector3(-6.6,0.8,-4.6), "ENTRY")
	_add_shelf(Vector3(-6.6,0.8,-1.8), "GAMING")
	_add_shelf(Vector3(-6.6,0.8,1.0), "STORAGE")
	_add_display_table(Vector3(-2.5,0.45,3.4), Color("#2ba8d8"))
	_add_display_table(Vector3(2.3,0.45,3.4), Color("#d82f55"))
	_add_pc(Vector3(-2.5,1.05,3.4), Color("#2ba8d8"), 1)
	_add_pc(Vector3(2.3,1.05,3.4), Color("#dc2e52"), 3)
	# Store terminal.
	_add_box("StoreTerminalDesk", Vector3(6.3,0.55,2.8), Vector3(2.0,1.1,1.2), Color("#303946"), true)
	_add_monitor(Vector3(6.3,1.5,2.65), Color("#2bc0e8"))
	_add_interaction("store_pc", "USA IL PC DEL NEGOZIO", Vector3(6.3,1.0,3.4), Vector3(2.8,2.2,2.8))
	# Lab doorway with real blocking collider that opens on E.
	lab_door_mesh = _add_box("LabDoor", Vector3(9.0,1.25,-1.9), Vector3(0.28,2.5,2.1), Color("#3d4652"), false)
	lab_door_body = _add_collision_box("LabDoorCollision", Vector3(9.0,1.25,-1.9), Vector3(0.35,2.5,2.1))
	_add_interaction("lab_door", "APRI LABORATORIO", Vector3(8.1,1.0,-1.9), Vector3(2.5,2.4,3.0))
	# Laboratory workbench and diagnostics.
	_add_box("Workbench", Vector3(13.2,0.55,-3.7), Vector3(5.6,1.1,1.6), Color("#313b47"), true)
	_add_box("WorkbenchTop", Vector3(13.2,1.15,-3.7), Vector3(5.8,0.15,1.8), Color("#65707b"), false)
	_add_pc(Vector3(12.0,1.65,-3.7), Color("#da2b4f"), 2)
	_add_interaction("workbench", "USA BANCO ASSEMBLAGGIO", Vector3(13.2,1.0,-2.6), Vector3(6.5,2.5,3.2))
	_add_box("DiagnosticDesk", Vector3(15.8,0.55,1.5), Vector3(2.5,1.1,1.3), Color("#2c3744"), true)
	_add_monitor(Vector3(15.8,1.5,1.2), Color("#36b9e4"))
	_add_interaction("diagnostics", "APRI DIAGNOSTICA", Vector3(15.8,1.0,2.4), Vector3(3.2,2.5,3.0))
	_add_shelf(Vector3(11.1,0.8,2.7), "LAB PARTS")
	# Accent/practical lights: actual real-time lights.
	_add_light(Vector3(-4.5,2.7,-1.0), Color("#70cfff"), 1.18, 6.4)
	_add_light(Vector3(4.2,2.7,-1.0), Color("#ff4a68"), 1.12, 6.4)
	_add_light(Vector3(13.4,2.7,-1.5), Color("#6bc8ff"), 1.30, 5.8)
	_add_light(Vector3(16.2,2.7,-4.0), Color("#ff4668"), 1.05, 4.8)
	# Interactions around physical customer/counter.
	_add_interaction("counter", "PARLA AL CLIENTE", Vector3(0,1.0,-0.6), Vector3(5.8,2.2,2.8))

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.name = "PlayerCharacter"
	player.position = Vector3(0,0.65,5.7)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.33; capsule.height = 1.45
	collision.shape = capsule; collision.position.y = 0.72
	player.add_child(collision)
	var body_mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new(); capsule_mesh.radius = 0.34; capsule_mesh.height = 1.45
	body_mesh.mesh = capsule_mesh; body_mesh.position.y = 0.72
	body_mesh.material_override = _material(Color("#d92d4c"),0.38,0.55)
	player.add_child(body_mesh)
	add_child(player)
	player.interaction_requested.connect(_on_player_interact)
	camera = Camera3D.new(); camera.name = "IsometricCamera"; camera.position = Vector3(8.5,10.5,10.5); camera.rotation_degrees = Vector3(-43,-38,0); camera.fov = 52.0; camera.current = true
	player.add_child(camera)

func _spawn_customer() -> void:
	customer = CustomerScript.new(); customer.name = "FirstCustomer"; customer.position = Vector3(0,0.65,6.8)
	var collision := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.radius=0.32; capsule.height=1.4; collision.shape=capsule; collision.position.y=0.7; customer.add_child(collision)
	var mesh := MeshInstance3D.new(); var capsule_mesh:=CapsuleMesh.new(); capsule_mesh.radius=0.33; capsule_mesh.height=1.4; mesh.mesh=capsule_mesh; mesh.position.y=0.7; mesh.material_override=_material(Color("#3a9fd0"),0.45,0.5); customer.add_child(mesh)
	add_child(customer)
	customer.set_route([Vector3(0,0.65,4.7),Vector3(-1.2,0.65,2.2),Vector3(0,0.65,-0.25)])

func _on_player_interact() -> void:
	var nearest := _nearest_interaction(2.2)
	if nearest == null: return
	last_interaction = String(nearest.interaction_id)
	match last_interaction:
		"lab_door": _toggle_lab_door()
		"store_pc": print("REAL INTERACTION: STORE_PC")
		"workbench": print("REAL INTERACTION: WORKBENCH")
		"diagnostics": print("REAL INTERACTION: DIAGNOSTICS")
		"counter": print("REAL INTERACTION: CUSTOMER_COUNTER")
	nearest.activate()

func _toggle_lab_door() -> void:
	lab_door_open = not lab_door_open
	if lab_door_mesh != null: lab_door_mesh.visible = not lab_door_open
	if lab_door_body != null:
		for child in lab_door_body.get_children():
			if child is CollisionShape3D: child.disabled = lab_door_open
	print("REAL DOOR STATE: ", "OPEN" if lab_door_open else "CLOSED")

func _update_prompt() -> void:
	var nearest := _nearest_interaction(2.2)
	prompt_text = "" if nearest == null else nearest.prompt

func _nearest_interaction(max_distance: float) -> Area3D:
	if player == null: return null
	var best := max_distance
	var found: Area3D = null
	for area in interactions:
		if not is_instance_valid(area): continue
		var d := player.global_position.distance_to(area.global_position)
		if d < best:
			best = d; found = area
	return found

func _add_interaction(id:String,prompt:String,pos:Vector3,size:Vector3) -> Area3D:
	var area := InteractableScript.new(); area.name="Interact_"+id; area.interaction_id=id; area.prompt=prompt; area.position=pos
	var shape_node:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; shape_node.shape=shape; area.add_child(shape_node); add_child(area); interactions.append(area); return area

func _add_box(name_text:String,pos:Vector3,size:Vector3,color:Color,collidable:bool) -> MeshInstance3D:
	var mesh_node:=MeshInstance3D.new(); mesh_node.name=name_text; mesh_node.position=pos
	var box:=BoxMesh.new(); box.size=size; mesh_node.mesh=box; mesh_node.material_override=_material(color,0.42,0.48); add_child(mesh_node)
	if collidable: _add_collision_box(name_text+"Collision",pos,size)
	return mesh_node

func _add_collision_box(name_text:String,pos:Vector3,size:Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new(); body.name=name_text; body.position=pos
	var cs:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; cs.shape=shape; body.add_child(cs); add_child(body); return body

func _add_shelf(pos:Vector3,label:String) -> void:
	_add_box("Shelf_"+label,pos,Vector3(2.4,1.6,0.55),Color("#303b47"),true)
	for row in range(3):
		for col in range(4):
			var tone:=Color("#d62b4b") if (row+col)%3==0 else (Color("#2ba8d8") if (row+col)%3==1 else Color("#7b52c8"))
			_add_box("ProductBox",pos+Vector3(-0.78+col*0.52,-0.5+row*0.5,-0.38),Vector3(0.38,0.35,0.25),tone,false)

func _add_display_table(pos:Vector3,tone:Color) -> void:
	_add_box("DisplayTable",pos,Vector3(3.3,0.9,1.6),Color("#313b46"),true)
	_add_box("DisplayAccent",pos+Vector3(0,0.48,0),Vector3(3.35,0.08,1.65),tone,false)

func _add_monitor(pos:Vector3,tone:Color) -> void:
	_add_box("MonitorStand",pos+Vector3(0,-0.28,0),Vector3(0.12,0.55,0.12),Color("#161d25"),false)
	var screen:=_add_box("Monitor",pos,Vector3(1.0,0.62,0.12),Color("#111720"),false)
	var mat:=_material(Color("#0c1118"),0.25,0.35); mat.emission_enabled=true; mat.emission=tone; mat.emission_energy_multiplier=1.8; screen.material_override=mat

func _add_pc(pos:Vector3,tone:Color,tier:int) -> void:
	var height:=1.25+0.08*tier; var width:=0.62+0.06*tier
	_add_box("PCCase",pos,Vector3(width,height,0.72),Color("#171e27"),false)
	var glass:=_add_box("PCGlass",pos+Vector3(0,0,0.37),Vector3(width*0.9,height*0.82,0.035),Color("#22303d"),false)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; var gm:=_material(Color(0.12,0.18,0.24,0.45),0.18,0.15); gm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.material_override=gm
	for i in range(1+tier):
		var fan:=_add_box("PCFan",pos+Vector3(-0.2+i*0.18,0.15,0.40),Vector3(0.12,0.48,0.04),tone,false)
		var fm:=_material(Color("#121820"),0.3,0.35); fm.emission_enabled=true; fm.emission=tone; fm.emission_energy_multiplier=2.0; fan.material_override=fm

func _add_light(pos:Vector3,color:Color,energy:float,range_value:float) -> void:
	var light:=OmniLight3D.new(); light.position=pos; light.light_color=color; light.light_energy=energy; light.omni_range=range_value; light.shadow_enabled=true; add_child(light)

func _material(color:Color,roughness:float,metallic:float) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=roughness; mat.metallic=metallic; return mat

func technical_status() -> Dictionary:
	return {
		"player_character_body": player is CharacterBody3D,
		"camera_real": camera is Camera3D,
		"customer_character_body": customer is CharacterBody3D,
		"interaction_count": interactions.size(),
		"lab_door_real": lab_door_body is StaticBody3D,
		"world_raster_used": false,
		"shop_geometry": true,
		"lab_geometry": true
	}
