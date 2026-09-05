extends "res://beta_hotfix.gd"

const PremiumWorldData = preload("res://premium_world_data.gd")
const PremiumCharsData = preload("res://premium_chars_data.gd")

var premium_atlas: Texture2D
var premium_chars: Texture2D
var visual_phase: float = 0.0
var lab_player := Vector2(960, 810)
var lab_near_zone := ""
var shop_blockers := [
	Rect2(0,100,350,760),
	Rect2(480,155,650,255),
	Rect2(560,390,520,190),
	Rect2(430,570,590,255),
	Rect2(1360,500,500,405)
]
var lab_blockers := [
	Rect2(420,135,1050,410),
	Rect2(0,500,500,580),
	Rect2(1120,610,800,470)
]

func _ready() -> void:
	premium_atlas = _texture_from_webp_data(PremiumWorldData.DATA,"world")
	premium_chars = _texture_from_webp_data(PremiumCharsData.DATA,"characters")
	if premium_atlas == null or premium_chars == null:
		printerr("PREMIUM WEBP LOAD FAILURE")
	else:
		print("PREMIUM WEBP LOAD PASS")
	super._ready()
	zones = [
		{"id":"terminal","rect":Rect2(290,190,300,220)},
		{"id":"customer","rect":Rect2(610,205,480,210)},
		{"id":"lab","rect":Rect2(1100,120,235,260)},
		{"id":"inventory","rect":Rect2(1420,500,350,330)},
		{"id":"used","rect":Rect2(1170,560,220,250)},
		{"id":"exit","rect":Rect2(770,915,390,120)}
	]
	player = Vector2(960,820)
	queue_redraw()

func _texture_from_webp_data(encoded:String,label:String) -> Texture2D:
	if encoded.is_empty():
		printerr("PREMIUM WEBP DATA EMPTY: ",label)
		return null
	var bytes:PackedByteArray = Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		printerr("PREMIUM WEBP BASE64 DECODE FAILED: ",label)
		return null
	var image := Image.new()
	var err:Error = image.load_webp_from_buffer(bytes)
	if err != OK or image.is_empty():
		printerr("PREMIUM WEBP IMAGE DECODE FAILED: ",label," code=",err)
		return null
	print("PREMIUM WEBP READY: ",label," ",image.get_width(),"x",image.get_height())
	return ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	visual_phase += delta
	var held_speed := speed
	if screen == "shop_floor": speed = 0.0
	super._process(delta)
	speed = held_speed
	if screen == "shop_floor":
		_move_world_player(delta,false)
		_update_near_zone()
	elif screen == "lab_floor":
		_move_world_player(delta,true)
		_update_lab_zone()
	queue_redraw()

func _move_world_player(delta: float,in_lab: bool) -> void:
	var d := Input.get_vector("move_left","move_right","move_up","move_down")
	if d.length() <= 0.05: return
	var old := lab_player if in_lab else player
	var candidate := old + d.normalized()*held_world_speed()*delta
	candidate.x = clampf(candidate.x,100.0,1820.0)
	candidate.y = clampf(candidate.y,145.0,970.0)
	var blockers: Array = lab_blockers if in_lab else shop_blockers
	var body := Rect2(candidate-Vector2(24,18),Vector2(48,42))
	for b in blockers:
		if body.intersects(b):
			candidate = old
			break
	if in_lab: lab_player = candidate
	else:
		player = candidate
		player_dir = d.normalized()
		hour += delta*0.12

func held_world_speed() -> float:
	return 330.0

func _input(event: InputEvent) -> void:
	if screen == "lab_floor":
		if event.is_action_pressed("cancel"):
			screen="shop_floor"; lab_near_zone=""; _beep(420); queue_redraw(); return
		if event.is_action_pressed("interact"):
			match lab_near_zone:
				"bench":
					if current_job >= 0 and job_state in ["accepted","working"]: screen="build"
					else: _notify("Non hai un lavoro attivo",false)
				"diagnostic":
					if current_job >= 0: screen="diagnostics"
					else: _notify("Nessun PC da diagnosticare",false)
				"door": screen="shop_floor"
			queue_redraw(); return
	super._input(event)

func _interact_zone() -> void:
	if near_zone == "lab":
		lab_player=Vector2(930,820); lab_near_zone=""; screen="lab_floor"; _beep(520); queue_redraw(); return
	super._interact_zone()

func _update_lab_zone() -> void:
	lab_near_zone=""
	var candidates=[
		{"id":"bench","rect":Rect2(540,250,800,250)},
		{"id":"diagnostic","rect":Rect2(600,230,330,210)},
		{"id":"door","rect":Rect2(190,110,300,300)}
	]
	var best:=99999.0
	for z in candidates:
		var r:Rect2=z.rect
		var q:=Vector2(clampf(lab_player.x,r.position.x,r.end.x),clampf(lab_player.y,r.position.y,r.end.y))
		var dist:=lab_player.distance_to(q)
		if dist<85.0 and dist<best:
			best=dist; lab_near_zone=String(z.id)

func _draw() -> void:
	if screen=="lab_floor":
		_draw_lab_floor()
		if notification!="":
			_panel(Rect2(650,35,620,62),Color("#101820"),CYAN,2); _txt(Vector2(680,76),notification,21,WHITE)
		return
	super._draw()

func _draw_shop_environment() -> void:
	_draw_atlas_region(Rect2(0,0,VW,VH),Rect2(0,0,640,360))
	draw_rect(Rect2(0,0,VW,VH),Color(0.0,0.0,0.0,0.05),true)
	for z in zones:
		if String(z.id)==near_zone:
			var r:Rect2=z.rect
			draw_rect(r,Color(0.08,0.55,1.0,0.05),true)
			draw_rect(r,Color(0.25,0.8,1.0,0.65),false,2.0)

func _draw_floor() -> void:
	_draw_shop_environment()
	_draw_world_customer(Vector2(700,330))
	_draw_world_player(player,false)
	if player.y < 430.0: _shop_patch(Rect2(470,155,680,300))
	if player.y < 610.0: _shop_patch(Rect2(555,385,560,235))
	if player.y < 830.0: _shop_patch(Rect2(405,560,645,300))
	if player.x > 1320.0 and player.y < 920.0: _shop_patch(Rect2(1340,500,540,430))
	_draw_hud()
	if near_zone!="": _button(_btn(800,885,320,62),T("interact"))
	_panel(Rect2(35,145,390,190),Color(0.025,0.032,0.045,0.90),Color("#3c4654"),2)
	_txt(Vector2(62,183),T("objective"),16,RED)
	_txt(Vector2(62,228),_objective_text(),22,WHITE)
	_txt(Vector2(62,278),"WASD • E • TAB/I • J • ESC",15,MUTED)

func _draw_lab_floor() -> void:
	_draw_atlas_region(Rect2(0,0,VW,VH),Rect2(640,0,640,360))
	draw_rect(Rect2(0,0,VW,VH),Color(0,0,0,0.04),true)
	_draw_world_player(lab_player,true)
	if lab_player.y < 560.0: _lab_patch(Rect2(400,145,1080,440))
	if lab_player.x < 560.0 and lab_player.y < 970.0: _lab_patch(Rect2(0,490,520,590))
	if lab_player.x > 1060.0 and lab_player.y < 1000.0: _lab_patch(Rect2(1080,600,840,480))
	_draw_hud()
	_panel(Rect2(35,145,420,160),Color(0.025,0.032,0.045,0.90),Color("#3d4857"),2)
	_txt(Vector2(62,182),"LABORATORIO",18,RED)
	_txt(Vector2(62,225),"Banco • diagnostica • ricambi • strumenti",18,WHITE)
	_txt(Vector2(62,268),"E interagisci  •  ESC torna al negozio",14,MUTED)
	if lab_near_zone!="": _button(_btn(800,885,320,62),"E  INTERAGISCI")

func _draw_world_player(p:Vector2,in_lab:bool) -> void:
	var moving := Input.get_vector("move_left","move_right","move_up","move_down").length()>0.05
	var bob:float = sin(visual_phase*12.0)*5.0 if moving else sin(visual_phase*2.2)*1.5
	draw_set_transform(p+Vector2(0,40),0.0,Vector2(1.0,0.38))
	draw_circle(Vector2.ZERO,38.0,Color(0,0,0,0.46))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	if premium_chars != null:
		draw_texture_rect_region(premium_chars,Rect2(p.x-55,p.y-125+bob,110,190),Rect2(0,0,128,220))
	else:
		super._draw_player()
	if moving: draw_circle(p+Vector2(player_dir.x*22,58),4.0,Color(0.9,0.1,0.18,0.50))

func _draw_world_customer(p:Vector2) -> void:
	draw_set_transform(p+Vector2(0,38),0.0,Vector2(1.0,0.40))
	draw_circle(Vector2.ZERO,34.0,Color(0,0,0,0.38))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	if premium_chars != null:
		draw_texture_rect_region(premium_chars,Rect2(p.x-54,p.y-120,108,188),Rect2(128,0,128,220))
	else:
		super._draw_customer(p)
	if current_job>=0: _txt(p+Vector2(38,-92),"!",34,YELLOW)

func _draw_player() -> void:
	_draw_world_player(player,false)

func _draw_customer(p:Vector2) -> void:
	_draw_world_customer(p)

func _draw_case() -> void:
	_draw_atlas_region(Rect2(290,135,1130,785),Rect2(0,360,640,445))
	draw_rect(Rect2(290,135,1130,785),Color(0,0,0,0.03),true)
	for k in build_slots.keys():
		var c:Dictionary=_component(String(build_slots[k]))
		var r:Rect2=_build_drop_rect(String(k))
		draw_rect(r,Color(0.1,0.85,0.65,0.07),true)
		draw_rect(r,Color(0.35,1.0,0.65,0.82),false,3.0)
		_panel(Rect2(r.position+Vector2(8,8),Vector2(minf(240.0,r.size.x-16.0),36)),Color(0.015,0.025,0.035,0.88),Color(0.2,0.8,0.6,0.55),1.0)
		_txt(r.position+Vector2(16,34),String(c.name),13,WHITE)

func _draw_online_shop() -> void:
	_draw_header(T("shop"))
	var cats=["Tutti","CPU","Motherboard","RAM","GPU","Storage","PSU","Case","Cooling","Fans"]
	_panel(Rect2(38,140,315,790),Color(0.02,0.026,0.038,0.95),Color("#2a3442"),2)
	for i in range(cats.size()):
		var rr=Rect2(65,175+i*62,270,50)
		if selected_shop_category==cats[i]: draw_rect(rr,Color("#351018"),true)
		_txt(rr.position+Vector2(16,33),cats[i],18,RED if selected_shop_category==cats[i] else WHITE)
	var list:=_shop_components()
	for i in range(min(list.size(),8)):
		var c:Dictionary=list[i]
		var col:=i%4; var row:=i/4
		var r:=Rect2(385+col*365,205+row*330,325,285)
		_panel(r,Color(0.025,0.035,0.05,0.96),Color("#343d4a"),2)
		_draw_component_photo(Rect2(r.position+Vector2(18,18),Vector2(289,105)),String(c.category),i)
		_txt(r.position+Vector2(20,150),String(c.name),17,WHITE)
		_txt(r.position+Vector2(20,181),String(c.category),14,MUTED)
		_txt(r.position+Vector2(20,220),"€ %d"%int(c.price),22,GREEN)
		var compat:=_compatibility_reason(c)==""
		_txt(r.position+Vector2(20,252),"COMPATIBILE" if compat else "INCOMPATIBILE",12,GREEN if compat else RED)
		_button(Rect2(r.position+Vector2(177,228),Vector2(128,44)),T("buy"))
	_txt(Vector2(1510,108),"SALDO € %d"%money,24,GREEN)
	_button(_btn(55,950,230,70),T("back"))

func _draw_component_photo(dest:Rect2,cat:String,idx:int) -> void:
	var src:=Rect2(70,110,160,90)
	match cat:
		"CPU": src=Rect2(225,95,95,75)
		"Motherboard": src=Rect2(160,70,190,120)
		"RAM": src=Rect2(270,70,75,120)
		"GPU": src=Rect2(165,185,250,85)
		"Storage": src=Rect2(345,110,100,75)
		"PSU": src=Rect2(105,240,150,95)
		"Cooling": src=Rect2(210,70,140,115)
		"Fans": src=Rect2(430,70,130,170)
		"Case": src=Rect2(100,40,420,300)
	src.position.y += 360.0
	_draw_atlas_region(dest,src)
	draw_rect(dest,Color(0.85,0.04,0.12,0.18),false,2.0)

func _draw_header(title:String) -> void:
	if screen in ["diagnostics","build","benchmark","os_install"]:
		_draw_atlas_region(Rect2(0,0,VW,VH),Rect2(640,0,640,360))
	else:
		_draw_atlas_region(Rect2(0,0,VW,VH),Rect2(0,0,640,360))
	draw_rect(Rect2(0,0,VW,VH),Color(0,0,0,0.58),true)
	_panel(Rect2(20,18,1880,98),Color(0.012,0.018,0.026,0.94),Color("#3a424e"),2)
	draw_rect(Rect2(20,18,6,98),RED,true)
	_txt(Vector2(52,78),"PC GAME EMPIRE",25,WHITE)
	_txt(Vector2(700,78),title,30,RED)
	_txt(Vector2(1640,78),"€ %d"%money,24,GREEN)

func _draw_neon_backdrop() -> void:
	_draw_atlas_region(Rect2(0,0,VW,VH),Rect2(0,0,640,360))
	draw_rect(Rect2(0,0,VW,VH),Color(0.005,0.008,0.014,0.56),true)
	draw_circle(Vector2(1530,270),340.0,Color(0.75,0.0,0.2,0.08))
	draw_circle(Vector2(1300,760),320.0,Color(0.25,0.05,0.85,0.07))

func _draw_dim_bg() -> void:
	_draw_neon_backdrop(); draw_rect(Rect2(0,0,VW,VH),Color(0,0,0,0.52),true)

func _panel(r:Rect2,c:=PANEL,b:=Color("#2b3748"),width:=2.0) -> void:
	draw_rect(Rect2(r.position+Vector2(7,9),r.size),Color(0,0,0,0.30),true)
	draw_rect(r,c,true)
	draw_rect(r,b,false,width)
	if r.size.x>70 and r.size.y>45:
		draw_line(r.position+Vector2(2,2),r.position+Vector2(r.size.x-2,2),Color(1,1,1,0.06),1)

func _button(r:Rect2,label:String,active:=true) -> void:
	var hover:=active and r.has_point(get_local_mouse_position())
	var fill:=Color("#202936") if hover else (Color("#121923") if active else Color("#0c1117"))
	var edge:=Color("#ff3154") if hover else (Color("#9d2038") if active else Color("#303741"))
	_panel(r,fill,edge,3.0 if hover else 2.0)
	if active: draw_rect(Rect2(r.position,Vector2(5,r.size.y)),RED if not hover else Color("#ff6a80"),true)
	_txt(r.position+Vector2(24,r.size.y*0.64),label,22,WHITE if active else Color("#5d6672"))

func _shop_patch(dest:Rect2) -> void:
	var src:=Rect2(dest.position/Vector2(3.0,3.0),dest.size/Vector2(3.0,3.0))
	_draw_atlas_region(dest,src)

func _lab_patch(dest:Rect2) -> void:
	var src:=Rect2(dest.position/Vector2(3.0,3.0),dest.size/Vector2(3.0,3.0))
	src.position.x += 640.0
	_draw_atlas_region(dest,src)

func _draw_atlas_region(dest:Rect2,src:Rect2) -> void:
	if premium_atlas != null:
		draw_texture_rect_region(premium_atlas,dest,src)
	else:
		draw_rect(dest,Color("#111720"),true)
