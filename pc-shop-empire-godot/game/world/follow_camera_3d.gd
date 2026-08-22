extends Camera3D

@export var offset := Vector3(7.6, 10.8, 10.2)
@export var follow_speed := 7.5
@export var look_height := 0.85
var target: Node3D

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = 14.5
	near = 0.1
	far = 80.0
	current = true

func set_target(node: Node3D) -> void:
	target = node
	if target != null:
		global_position = target.global_position + offset
		look_at(target.global_position + Vector3(0,look_height,0), Vector3.UP)

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target): return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	look_at(target.global_position + Vector3(0,look_height,0), Vector3.UP)
