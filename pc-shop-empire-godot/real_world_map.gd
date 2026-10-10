extends Node2D

const PropScript = preload("res://real_world_prop.gd")
const ActorScript = preload("res://real_world_actor.gd")

var room := ""
var player_body: CharacterBody2D
var customer_body: CharacterBody2D
var interactions:Array = []
var prop_count := 0
var collision_count := 0
var interaction_count := 0

func _ready() -> void:
	show_behind_parent = true
	z_index = -100

func build_room(room_name:String,start_pos:Vector2) -> void:
	room=room_name
	for child in get_children(): child.queue_free()
	interactions.clear(); prop_count=0; collision_count=0; interaction_count=0
	if room=="shop": _build_shop()
	else: _build_lab()
	player_body=ActorScript.new()
	player_body.name="RealPlayer"
	player_body.configure("player","TECNICO",Color("#e42a45"))
	player_body.position=start_pos
	player_body.collision_layer=1; player_body.collision_mask=1
	add_child(player_body)
	_update_actor_depth()

func _build_shop() -> void:
	# Floor is made of independent tiles, not one raster backdrop.
	for yy in range(0,3):
		for xx in range(0,4):
			_add_prop("floor_tile",Vector2(340+xx*430,280+yy*300),Vector2(430,300),"",Color("#3d5368"),xx+yy,false)
	# Structural walls and entrance.
	_add_prop("wall",Vector2(960,150),Vector2(1680,72),"PC GAME EMPIRE",Color("#dc2943"),0,true)
	_add_prop("wall",Vector2(95,540),Vector2(70,780),"",Color("#2b9ed2"),0,true)
	_add_prop("wall",Vector2(1825,540),Vector2(70,780),"",Color("#dc2943"),0,true)
	_add_prop("wall",Vector2(470,980),Vector2(740,55),"",Color("#2b9ed2"),0,true)
	_add_prop("wall",Vector2(1450,980),Vector2(740,55),"",Color("#dc2943"),0,true)
	_add_prop("door",Vector2(960,995),Vector2(190,120),"INGRESSO",Color("#dc2943"),0,false,"exit")
	# Service counter is a real collision object. Customer stands physically behind it.
	_add_prop("counter",Vector2(930,365),Vector2(570,125),"ASSISTENZA & ORDINI",Color("#dc2943"),0,true,"counter")
	customer_body=ActorScript.new(); customer_body.name="FirstCustomer"; customer_body.configure("customer","CLIENTE",Color("#3aa7d8")); customer_body.position=Vector2(930,245); customer_body.collision_layer=1; customer_body.collision_mask=1; add_child(customer_body)
	_add_interaction("customer",Vector2(930,325),Vector2(250,105))
	# Real terminal and lab door.
	_add_prop("terminal",Vector2(350,345),Vector2(220,105),"CATALOGO",Color("#28a8d6"),1,true,"terminal")
	_add_prop("door",Vector2(1615,300),Vector2(210,170),"LABORATORIO",Color("#dc2943"),0,true,"lab")
	# Independent merchandise fixtures.
	_add_prop("shelf",Vector2(325,650),Vector2(300,125),"COMPONENTI",Color("#2da8dc"),0,true,"display_components")
	_add_prop("shelf",Vector2(325,855),Vector2(300,125),"PERIFERICHE",Color("#b63bd0"),1,true,"display_peripherals")
	_add_prop("display",Vector2(780,670),Vector2(370,120),"GAMING DISPLAY",Color("#dc2943"),2,true,"display_pc")
	_add_prop("display",Vector2(1230,670),Vector2(370,120),"CREATOR DISPLAY",Color("#2da8dc"),3,true,"display_pc")
	# Physical showcased PCs.
	_add_prop("pc",Vector2(690,610),Vector2(105,135),"",Color("#2da8dc"),0,false)
	_add_prop("pc",Vector2(790,610),Vector2(105,135),"",Color("#bd42df"),1,false)
	_add_prop("pc",Vector2(1140,610),Vector2(105,135),"",Color("#dc2943"),2,false)
	_add_prop("pc",Vector2(1245,610),Vector2(105,135),"",Color("#ff8a32"),3,false)
	# Product boxes are separate props and can later be data-driven stock nodes.
	for i in range(5): _add_prop("box",Vector2(1455+i*60,755+(i%2)*65),Vector2(52,38),"",Color("#d62b45") if i%2==0 else Color("#2aa6d6"),i,false)

func _build_lab() -> void:
	for yy in range(0,3):
		for xx in range(0,4): _add_prop("floor_tile",Vector2(340+xx*430,280+yy*300),Vector2(430,300),"",Color("#31556a"),xx+yy,false)
	_add_prop("wall",Vector2(960,150),Vector2(1680,72),"PC GAME EMPIRE • LAB",Color("#dc2943"),0,true)
	_add_prop("wall",Vector2(95,540),Vector2(70,780),"",Color("#2aa6d6"),0,true)
	_add_prop("wall",Vector2(1825,540),Vector2(70,780),"",Color("#dc2943"),0,true)
	_add_prop("wall",Vector2(960,980),Vector2(1680,55),"",Color("#2aa6d6"),0,true)
	_add_prop("door",Vector2(270,300),Vector2(210,170),"NEGOZIO",Color("#2aa6d6"),0,true,"door")
	# Main assembly bench and diagnostic terminal are independent real objects.
	_add_prop("workbench",Vector2(980,475),Vector2(710,165),"BANCO ASSEMBLAGGIO",Color("#dc2943"),0,true,"bench")
	_add_prop("terminal",Vector2(1470,430),Vector2(250,115),"DIAGNOSTICA",Color("#2aa6d6"),2,true,"diagnostic")
	_add_prop("toolrack",Vector2(650,265),Vector2(430,160),"UTENSILI",Color("#dc2943"),0,true)
	_add_prop("cabinet",Vector2(1540,710),Vector2(270,125),"RICAMBI",Color("#2aa6d6"),0,true,"parts")
	_add_prop("shelf",Vector2(390,720),Vector2(330,130),"STOCK LAB",Color("#8f45d6"),2,true,"parts")
	# Several work-in-progress machines are real nodes.
	_add_prop("pc",Vector2(760,420),Vector2(115,145),"",Color("#dc2943"),2,false)
	_add_prop("pc",Vector2(1200,420),Vector2(115,145),"",Color("#2aa6d6"),1,false)
	for i in range(7): _add_prop("box",Vector2(620+i*75,805+(i%2)*55),Vector2(58,42),"",Color("#d62b45") if i%3==0 else Color("#496077"),i,false)

func _add_prop(kind:String,pos:Vector2,size:Vector2,text:String,tone:Color,v:int,collidable:bool=true,interaction_id:String="") -> Node2D:
	var prop:=PropScript.new(); prop.name="Prop_%s_%d"%[kind,prop_count]; prop.configure(kind,size,text,tone,v); prop.position=pos; prop.z_index=clampi(int(pos.y/18.0),0,58); add_child(prop); prop_count+=1
	if collidable:
		var body:=StaticBody2D.new(); body.name="Collision_%s_%d"%[kind,collision_count]; body.position=pos+Vector2(0,-16); body.collision_layer=1; body.collision_mask=1
		var cs:=CollisionShape2D.new(); var shape:=RectangleShape2D.new(); shape.size=Vector2(maxf(45,size.x*0.86),maxf(38,minf(80,size.y*0.48))); cs.shape=shape; body.add_child(cs); add_child(body); collision_count+=1
	if interaction_id!="": _add_interaction(interaction_id,pos,Vector2(maxf(120,size.x+70),maxf(105,size.y+70)))
	return prop

func _add_interaction(id:String,pos:Vector2,size:Vector2) -> void:
	var area:=Area2D.new(); area.name="Interact_"+id+"_%d"%interaction_count; area.position=pos; area.collision_layer=2; area.collision_mask=1; area.set_meta("interaction_id",id)
	var cs:=CollisionShape2D.new(); var shape:=RectangleShape2D.new(); shape.size=size; cs.shape=shape; area.add_child(cs); add_child(area)
	interactions.append(area); interaction_count+=1

func drive_player(direction:Vector2,speed:float,delta:float) -> void:
	if player_body==null or not is_instance_valid(player_body): return
	player_body.drive(direction,speed,delta)
	player_body.position.x=clampf(player_body.position.x,125,1795)
	player_body.position.y=clampf(player_body.position.y,185,940)
	_update_actor_depth()

func _update_actor_depth() -> void:
	if player_body!=null and is_instance_valid(player_body): player_body.z_index=clampi(int(player_body.position.y/18.0),0,59)
	if customer_body!=null and is_instance_valid(customer_body): customer_body.z_index=clampi(int(customer_body.position.y/18.0),0,59)

func nearest_interaction(max_distance:float=105.0) -> String:
	if player_body==null: return ""
	var best:=max_distance; var found:=""
	for area_var in interactions:
		var area:Area2D=area_var
		if not is_instance_valid(area): continue
		var d:=player_body.position.distance_to(area.position)
		if d<best: best=d; found=String(area.get_meta("interaction_id",""))
	return found

func player_position() -> Vector2:
	return player_body.position if player_body!=null and is_instance_valid(player_body) else Vector2.ZERO

func has_real_structure() -> bool:
	return prop_count>=15 and collision_count>=6 and interaction_count>=3 and player_body!=null
