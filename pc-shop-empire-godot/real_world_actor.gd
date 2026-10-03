extends CharacterBody2D

var role := "player"
var accent := Color("#d7263d")
var facing := Vector2.DOWN
var walk_phase := 0.0
var moving := false
var display_name := ""

func configure(new_role:String,name_text:String,tone:Color) -> void:
	role=new_role; display_name=name_text; accent=tone
	var shape:=CollisionShape2D.new()
	var capsule:=CapsuleShape2D.new(); capsule.radius=18.0; capsule.height=44.0
	shape.shape=capsule; shape.position=Vector2(0,18)
	add_child(shape)
	queue_redraw()

func drive(input_dir:Vector2,speed:float,delta:float) -> void:
	moving=input_dir.length()>0.05
	if moving:
		facing=input_dir.normalized(); velocity=facing*speed; walk_phase+=delta*10.0
	else:
		velocity=Vector2.ZERO; walk_phase+=delta*2.0
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var bob:=sin(walk_phase)*3.0 if moving else sin(walk_phase)*0.8
	# Ground shadow is tied to the actual collision body.
	draw_set_transform(Vector2(0,48),0.0,Vector2(1.0,0.42))
	draw_circle(Vector2.ZERO,27,Color(0,0,0,0.38))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	# Legs with real alternating walk pose.
	var stride:=sin(walk_phase)*9.0 if moving else 0.0
	draw_line(Vector2(-9,25+bob),Vector2(-11+stride,50+bob),Color("#1b2430"),10)
	draw_line(Vector2(9,25+bob),Vector2(11-stride,50+bob),Color("#1b2430"),10)
	# Torso / jacket.
	var torso:=PackedVector2Array([Vector2(-23,-32+bob),Vector2(23,-32+bob),Vector2(29,18+bob),Vector2(18,33+bob),Vector2(-18,33+bob),Vector2(-29,18+bob)])
	draw_colored_polygon(torso,Color("#202b38") if role=="player" else Color("#35414e"))
	draw_polyline(PackedVector2Array([Vector2(-23,-32+bob),Vector2(23,-32+bob),Vector2(29,18+bob)]),Color("#5d6c7e"),2)
	# Accent stripe distinguishes protagonist from NPCs.
	draw_rect(Rect2(-20,-22+bob,40,6),accent,true)
	# Arms follow direction slightly.
	var arm_shift:=facing*4.0
	draw_line(Vector2(-21,-14+bob),Vector2(-34+arm_shift.x,15+bob+arm_shift.y),Color("#2c3845"),9)
	draw_line(Vector2(21,-14+bob),Vector2(34+arm_shift.x,15+bob+arm_shift.y),Color("#2c3845"),9)
	# Head/hair.
	draw_circle(Vector2(0,-52+bob),18,Color("#d6aa8d"))
	draw_arc(Vector2(0,-57+bob),18,PI,TAU,18,Color("#222a31"),8)
	# Facing indicator via eyes/visor.
	var look:=facing.normalized()*3.0
	draw_circle(Vector2(-6+look.x,-53+bob+look.y),2,Color("#111820"))
	draw_circle(Vector2(6+look.x,-53+bob+look.y),2,Color("#111820"))
	# Subtle rim light, not a fake sprite halo.
	draw_arc(Vector2(0,-5+bob),38,-2.4,-0.7,20,Color(accent.r,accent.g,accent.b,0.28),2)
	if display_name!="":
		draw_string(ThemeDB.fallback_font,Vector2(-38,-82+bob),display_name,HORIZONTAL_ALIGNMENT_CENTER,76,11,Color(0.88,0.92,0.96,0.78))
