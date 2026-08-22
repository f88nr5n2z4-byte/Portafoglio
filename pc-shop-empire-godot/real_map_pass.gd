extends "res://maximum_quality_final.gd"

const RealWorldMap = preload("res://real_world_map.gd")

var real_world:Node2D
var real_room := ""
var real_shop_position := Vector2(960,850)
var real_lab_position := Vector2(520,830)

func _ready() -> void:
	super._ready()
	real_world=RealWorldMap.new()
	real_world.name="REAL_GAMEPLAY_WORLD"
	add_child(real_world)
	_sync_real_room(true)
	print("REAL MAP READY: structured Node2D world enabled; premium raster disabled for explorable gameplay")

func _process(delta:float) -> void:
	_sync_real_room(false)
	super._process(delta)
	if real_world!=null and is_instance_valid(real_world):
		if screen=="shop_floor":
			player=real_world.player_position(); real_shop_position=player
		elif screen=="lab_floor":
			lab_player=real_world.player_position(); real_lab_position=lab_player

func _sync_real_room(force:bool) -> void:
	if real_world==null or not is_instance_valid(real_world): return
	var wanted := "shop" if screen=="shop_floor" else ("lab" if screen=="lab_floor" else "")
	real_world.visible=wanted!=""
	if wanted=="": return
	if force or wanted!=real_room:
		if real_room=="shop" and real_world.player_body!=null: real_shop_position=real_world.player_position()
		if real_room=="lab" and real_world.player_body!=null: real_lab_position=real_world.player_position()
		real_room=wanted
		real_world.build_room(wanted,real_shop_position if wanted=="shop" else real_lab_position)
		print("REAL MAP ROOM: ",wanted," props=",real_world.prop_count," collisions=",real_world.collision_count," interactions=",real_world.interaction_count)

# Critical override: movement now runs through an actual CharacterBody2D + physics collisions.
func _move_world_player(delta:float,in_lab:bool) -> void:
	if real_world==null or not is_instance_valid(real_world): return
	var wanted := "lab" if in_lab else "shop"
	if real_room!=wanted: return
	var direction:=Input.get_vector("move_left","move_right","move_up","move_down")
	real_world.drive_player(direction,310.0,delta)
	if direction.length()>0.05: player_dir=direction.normalized()

func _update_near_zone() -> void:
	near_zone=""
	if real_world!=null and real_room=="shop": near_zone=real_world.nearest_interaction(120.0)

func _update_lab_zone() -> void:
	lab_near_zone=""
	if real_world!=null and real_room=="lab": lab_near_zone=real_world.nearest_interaction(125.0)

func _interact_zone() -> void:
	if near_zone=="counter":
		near_zone="customer"
		super._interact_zone()
		return
	if near_zone.begins_with("display_"):
		_notify("Espositore reale • premi E vicino al prodotto per esaminarlo")
		_beep(640,0.06,"ui")
		return
	super._interact_zone()

# CRITICAL: these functions intentionally DO NOT draw premium_atlas backgrounds.
# The explorable scene behind the HUD is the real node/collision world.
func _draw_floor() -> void:
	_draw_hud()
	_panel(Rect2(34,142,390,172),Color(0.018,0.027,0.039,0.92),Color("#405166"),2)
	_txt(Vector2(60,178),"OBIETTIVO",13,RED)
	_txt(Vector2(60,220),_objective_text(),20,WHITE)
	_txt(Vector2(60,260),"WASD / Frecce • E interagisci",13,MUTED)
	_txt(Vector2(60,288),"MAPPA REALE • COLLISIONI ATTIVE",11,GREEN)
	if near_zone!="":
		var prompt:=_real_interaction_label(near_zone)
		_button(_btn(780,900,360,62),"E  "+prompt)

func _draw_lab_floor() -> void:
	_draw_hud()
	_panel(Rect2(34,142,415,172),Color(0.018,0.027,0.039,0.92),Color("#405166"),2)
	_txt(Vector2(60,178),"LABORATORIO REALE",14,RED)
	_txt(Vector2(60,220),"Banco • diagnostica • ricambi",18,WHITE)
	_txt(Vector2(60,258),"WASD / Frecce • E interagisci",13,MUTED)
	_txt(Vector2(60,288),"PROP + STATICBODY + AREA2D",11,GREEN)
	if lab_near_zone!="": _button(_btn(780,900,360,62),"E  "+_real_interaction_label(lab_near_zone))

func _real_interaction_label(id:String) -> String:
	match id:
		"customer","counter": return "PARLA AL CLIENTE"
		"terminal": return "USA IL PC"
		"lab": return "ENTRA NEL LAB"
		"exit": return "USCITA"
		"bench": return "USA BANCO"
		"diagnostic": return "DIAGNOSTICA"
		"door": return "TORNA AL NEGOZIO"
		"parts": return "RICAMBI"
		_: return "INTERAGISCI"

func real_map_status() -> Dictionary:
	if real_world==null: return {"ready":false}
	return {
		"ready":real_world.has_real_structure(),
		"room":real_room,
		"props":real_world.prop_count,
		"collisions":real_world.collision_count,
		"interactions":real_world.interaction_count,
		"player_is_character_body":real_world.player_body is CharacterBody2D,
		"premium_raster_used_for_gameplay":false
	}
