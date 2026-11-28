extends CharacterBody3D

signal interaction_requested

@export var move_speed := 4.8
@export var acceleration := 18.0
@export var friction := 22.0

var facing := Vector3.FORWARD

func _physics_process(delta: float) -> void:
	var input_2d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired := Vector3(input_2d.x, 0.0, input_2d.y)
	if desired.length() > 0.01:
		desired = desired.normalized()
		facing = desired
		velocity.x = move_toward(velocity.x, desired.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired.z * move_speed, acceleration * delta)
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.z), minf(1.0, delta * 10.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		interaction_requested.emit()

func drive_for_test(direction: Vector2, seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0:
		var step := minf(1.0 / 60.0, remaining)
		var d := Vector3(direction.x, 0.0, direction.y).normalized()
		velocity.x = d.x * move_speed
		velocity.z = d.z * move_speed
		if not is_on_floor(): velocity.y -= 20.0 * step
		move_and_slide()
		remaining -= step
