extends Node2D

var tech_tex := preload("res://assets/technician_sprite.svg")
var marco_tex := preload("res://assets/customer_marco_sprite.svg")
var giulia_tex := preload("res://assets/customer_giulia_sprite.svg")
var t := 0.0

func _ready() -> void:
	z_index = 20
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var game = get_parent()
	if not is_instance_valid(game):
		return
	if not ("mode" in game):
		return
	if game.mode == "shop":
		var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.05
		var bob := sin(t * 12.0) * 3.0 if moving else sin(t * 2.4) * 1.0
		var pp: Vector2 = game.player + Vector2(-36, -96 + bob)
		draw_texture_rect(tech_tex, Rect2(pp, Vector2(72,96)), false)
		var cp: Vector2 = game.customer_pos + Vector2(-34,-88)
		draw_texture_rect(marco_tex, Rect2(cp,Vector2(68,91)),false)
	elif game.mode == "build":
		_draw_build_hands()

func _draw_build_hands() -> void:
	# Forearms/hands at the workbench edge to make assembly feel first-person.
	draw_colored_polygon(PackedVector2Array([Vector2(275,720),Vector2(350,600),Vector2(410,610),Vector2(350,720)]),Color("#111319"))
	draw_colored_polygon(PackedVector2Array([Vector2(1005,720),Vector2(930,600),Vector2(870,610),Vector2(930,720)]),Color("#111319"))
	draw_circle(Vector2(385,605),28,Color("#d6a07d"))
	draw_circle(Vector2(895,605),28,Color("#d6a07d"))
	draw_line(Vector2(330,650),Vector2(365,625),Color("#e42132"),5)
	draw_line(Vector2(950,650),Vector2(915,625),Color("#e42132"),5)
