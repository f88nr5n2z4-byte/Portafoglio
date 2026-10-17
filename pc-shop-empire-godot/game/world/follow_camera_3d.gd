extends Camera3D

@export var offset:Vector3 = Vector3(7.6, 10.8, 10.2)
@export var follow_speed:float = 8.5
@export var look_height:float = 0.88
@export var ortho_size:float = 13.6
@export var occlusion_padding:float = 0.32
@export var occlusion_fade:float = 0.72
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
	for node:Node in hidden_last_frame: _set_occlusion_amount(node,0.0)
	hidden_last_frame.clear(); occludables.clear()

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target): return
	var desired:Vector3 = target.global_position + offset
	var blend:float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, blend)
	look_at(target.global_position + Vector3(0,look_height,0), Vector3.UP)
	_update_occlusion()

func _update_occlusion() -> void:
	for previous:Node in hidden_last_frame:
		if is_instance_valid(previous): _set_occlusion_amount(previous,0.0)
	hidden_last_frame.clear()
	if target==null: return
	var from:Vector3=global_position
	var to:Vector3=target.global_position+Vector3(0,look_height,0)
	for item:Dictionary in occludables:
		var node_value:Variant=item.get("node")
		if not (node_value is Node3D): continue
		var node:Node3D=node_value as Node3D
		if not is_instance_valid(node): continue
		var height_bias:float=float(item.get("height_bias",0.7))
		var point:Vector3=node.global_position+Vector3(0,height_bias,0)
		var distance:float=_distance_point_segment(point,from,to)
		var radius:float=float(item.get("radius",0.8))+occlusion_padding
		var camera_to_node:float=from.distance_to(point)
		var camera_to_target:float=from.distance_to(to)
		if distance<radius and camera_to_node<camera_to_target-0.45:
			_set_occlusion_amount(node,occlusion_fade)
			hidden_last_frame.append(node)

func _distance_point_segment(point:Vector3,a:Vector3,b:Vector3)->float:
	var ab:Vector3=b-a
	var len_sq:float=ab.length_squared()
	if len_sq<0.0001: return point.distance_to(a)
	var projected:float=(point-a).dot(ab)/len_sq
	var t:float=clampf(projected,0.0,1.0)
	return point.distance_to(a+ab*t)

func _set_occlusion_amount(node:Node,amount:float)->void:
	# GeometryInstance transparency preserves the object's silhouette and context while
	# revealing the player. It also avoids mutating cached/shared materials.
	if node is GeometryInstance3D: (node as GeometryInstance3D).transparency=amount
	for child:Node in node.get_children(): _set_occlusion_amount(child,amount)
