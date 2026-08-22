extends "res://game/world/store_world_3d.gd"

# Runtime world layer: every walkable surface has real physics, not only visible geometry.
func _build_environment() -> void:
	super._build_environment()
	_add_collision_box("ShopFloorCollision", Vector3(0,-0.15,0), Vector3(18,0.3,16))
	_add_collision_box("LabFloorCollision", Vector3(13.5,-0.15,-1.0), Vector3(9,0.3,12))
