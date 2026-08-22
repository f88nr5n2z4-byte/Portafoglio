extends CharacterBody3D

@export var walk_speed := 2.2
var waypoints: Array[Vector3] = []
var waypoint_index := 0
var waiting := false

func set_route(points: Array[Vector3]) -> void:
	waypoints = points
	waypoint_index = 0
	waiting = false

func _physics_process(delta: float) -> void:
	if waiting or waypoints.is_empty() or waypoint_index >= waypoints.size():
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var target := waypoints[waypoint_index]
	var flat := target - global_position
	flat.y = 0.0
	if flat.length() < 0.16:
		waypoint_index += 1
		if waypoint_index >= waypoints.size():
			waiting = true
		velocity = Vector3.ZERO
		return
	var dir := flat.normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	if not is_on_floor(): velocity.y -= 20.0 * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 7.0))
	move_and_slide()
