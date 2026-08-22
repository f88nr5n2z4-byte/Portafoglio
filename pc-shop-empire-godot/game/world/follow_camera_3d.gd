extends Camera3D

@export var offset := Vector3(7.6, 10.8, 10.2)
@export var follow_speed := 8.5
@export var look_height := 0.88
@export var ortho_size := 13.6
@export var occlusion_padding := 0.32
var target: Node3D
var occludables:Array[Dictionary] = []
var hidden_last_frame:Array[Node] = []

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = ortho_size
	near = 0.05
	far = 100.0
	current = true

func set_target(node: Node3D) -> void:
	target = node
	if target != null:
		global_position = target.global_position + offset
		look_at(target.global_position + Vector3(0,look_height,0), Vector3.UP)

func register_occludable(node:Node3D,radius:float=0.8,height_bias:float=0.7) -> void:
	if node==null: return
	occludables.append({"node":node,"radius":radius,"height_bias":height_bias})

func clear_occludables() -> void:
	for node in hidden_last_frame: _set_mesh_visibility(node,true)
	hidden_last_frame.clear(); occludables.clear()

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target): return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	look_at(target.global_position + Vector3(0,look_height,0), Vector3.UP)
	_update_occlusion()

func _update_occlusion() -> void:
	for node in hidden_last_frame:
		if is_instance_valid(node): _set_mesh_visibility(node,true)
	hidden_last_frame.clear()
	if target==null: return
	var from:=global_position
	var to:=target.global_position+Vector3(0,look_height,0)
	for item in occludables:
		var node:Node3D=item.get("node")
		if node==null or not is_instance_valid(node): continue
		var point:=node.global_position+Vector3(0,float(item.get("height_bias",0.7)),0)
		var distance:=_distance_point_segment(point,from,to)
		var radius:=float(item.get("radius",0.8))+occlusion_padding
		# Only cut away geometry that is actually between camera and player.
		var camera_to_node:=from.distance_to(point)
		var camera_to_target:=from.distance_to(to)
		if distance<radius and camera_to_node<camera_to_target-0.45:
			_set_mesh_visibility(node,false)
			hidden_last_frame.append(node)

func _distance_point_segment(point:Vector3,a:Vector3,b:Vector3)->float:
	var ab:=b-a
	var len_sq:=ab.length_squared()
	if len_sq<0.0001: return point.distance_to(a)
	var t:=clamp((point-a).dot(ab)/len_sq,0.0,1.0)
	return point.distance_to(a+ab*t)

func _set_mesh_visibility(node:Node,enabled:bool)->void:
	if node is MeshInstance3D: node.visible=enabled
	for child in node.get_children(): _set_mesh_visibility(child,enabled)
