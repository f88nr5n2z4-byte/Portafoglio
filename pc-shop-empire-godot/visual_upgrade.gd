extends "res://beta_hotfix.gd"

var vu_menu_tex := preload("res://assets/visual_menu_v2.svg")
var vu_shop_tex := preload("res://assets/visual_shop_v2.svg")
var vu_lab_tex := preload("res://assets/visual_lab_v2.svg")
var vu_build_tex := preload("res://assets/visual_build_v2.svg")
var vu_online_tex := preload("res://assets/visual_online_v2.svg")
var vu_phase: float = 0.0

func _process(delta: float) -> void:
	super._process(delta)
	vu_phase += delta

func _draw_neon_backdrop() -> void:
	draw_texture_rect(vu_menu_tex,Rect2(0,0,VW,VH),false)
	draw_rect(Rect2(0,0,VW,VH),Color(0.005,0.008,0.015,0.10),true)
	var pulse: float = 0.035 + 0.025 * (sin(vu_phase*1.7)*0.5+0.5)
	draw_circle(Vector2(1450,320),330.0,Color(0.75,0.15,1.0,pulse))
	draw_circle(Vector2(1130,820),300.0,Color(1.0,0.08,0.22,pulse*0.8))

func _draw_shop_environment() -> void:
	draw_texture_rect(vu_shop_tex,Rect2(0,0,VW,VH),false)
	# Localized light pool grounds the player in the 2.5D scene.
	draw_circle(player+Vector2(0,8),88.0,Color(0.12,0.68,1.0,0.055))
	for z in zones:
		if String(z.id)==near_zone:
			var r: Rect2 = z.rect
			draw_rect(r,Color(0.12,0.68,1.0,0.055),true)
			draw_rect(r,Color(0.28,0.82,1.0,0.82),false,3.0)

func _draw_case() -> void:
	# Full, high-detail close-up workbench instead of the old flat case diagram.
	draw_texture_rect(vu_build_tex,Rect2(250,118,1210,840),false)
	for k in build_slots.keys():
		var c: Dictionary = _component(String(build_slots[k]))
		var r: Rect2 = _build_drop_rect(String(k))
		draw_rect(r,Color(0.12,0.82,0.92,0.09),true)
		draw_rect(r,Color(0.28,0.92,1.0,0.90),false,3.0)
		_panel(Rect2(r.position+Vector2(6,6),Vector2(minf(r.size.x-12.0,230.0),34)),Color(0.02,0.035,0.055,0.88),Color(0.25,0.8,0.95,0.45),1.0)
		_txt(r.position+Vector2(15,30),String(c.name),13,WHITE)

func _draw_header(title:String) -> void:
	match screen:
		"online_shop":
			draw_texture_rect(vu_online_tex,Rect2(0,0,VW,VH),false)
			draw_rect(Rect2(0,0,VW,VH),Color(0.0,0.0,0.0,0.44),true)
		"diagnostics":
			draw_texture_rect(vu_lab_tex,Rect2(0,0,VW,VH),false)
			draw_rect(Rect2(0,0,VW,VH),Color(0.0,0.0,0.0,0.40),true)
		"build","benchmark","os_install":
			draw_texture_rect(vu_lab_tex,Rect2(0,0,VW,VH),false)
			draw_rect(Rect2(0,0,VW,VH),Color(0.0,0.0,0.0,0.46),true)
		_:
			draw_texture_rect(vu_shop_tex,Rect2(0,0,VW,VH),false)
			draw_rect(Rect2(0,0,VW,VH),Color(0.0,0.0,0.0,0.53),true)
	_panel(Rect2(22,20,1876,96),Color(0.018,0.025,0.038,0.94),Color(0.22,0.30,0.42,0.95),2.0)
	draw_rect(Rect2(22,20,5,96),Color("#ef294d"),true)
	_txt(Vector2(56,80),"PC GAME EMPIRE",25,WHITE)
	_txt(Vector2(700,80),title,30,RED)
	_txt(Vector2(1645,80),"€ %d"%money,24,GREEN)

func _draw_dim_bg() -> void:
	if screen=="job_offer" or screen=="result":
		draw_texture_rect(vu_shop_tex,Rect2(0,0,VW,VH),false)
	else:
		draw_texture_rect(vu_menu_tex,Rect2(0,0,VW,VH),false)
	draw_rect(Rect2(0,0,VW,VH),Color(0,0,0,0.64),true)

func _panel(r:Rect2,c:=PANEL,b:=Color("#2b3748"),width:=2.0) -> void:
	# Layered glass-metal panel with subtle shadow and inner edge.
	draw_rect(Rect2(r.position+Vector2(7,9),r.size),Color(0,0,0,0.28),true)
	draw_rect(r,c,true)
	draw_rect(r,b,false,width)
	if r.size.x>70.0 and r.size.y>45.0:
		draw_line(r.position+Vector2(2,2),r.position+Vector2(r.size.x-2,2),Color(1,1,1,0.06),1.0)
		draw_line(r.position+Vector2(2,r.size.y-2),r.position+Vector2(r.size.x-2,r.size.y-2),Color(0,0,0,0.28),1.0)

func _button(r:Rect2,label:String,active:=true) -> void:
	var hover: bool = active and r.has_point(get_local_mouse_position())
	var fill := Color("#202937") if hover else (Color("#131a24") if active else Color("#0e1218"))
	var edge := Color("#ff3154") if hover else (Color("#b9203c") if active else Color("#303845"))
	_panel(r,fill,edge,2.0 if not hover else 3.0)
	if active:
		draw_rect(Rect2(r.position+Vector2(0,0),Vector2(5,r.size.y)),Color("#ef294d") if not hover else Color("#ff6680"),true)
	_txt(r.position+Vector2(24,r.size.y*0.64),label,22,WHITE if active else Color("#5f6976"))

func _draw_floor() -> void:
	super._draw_floor()
	# Premium ambient HUD accents and scene depth vignette.
	draw_rect(Rect2(0,0,VW,6),Color(0.92,0.08,0.22,0.75),true)
	draw_rect(Rect2(0,VH-7,VW,7),Color(0.45,0.12,0.74,0.45),true)
	var scan_alpha: float = 0.035 + 0.015*sin(vu_phase*1.25)
	for y in range(120,1000,80):
		draw_line(Vector2(20,y),Vector2(1900,y),Color(0.2,0.45,0.7,scan_alpha),1.0)
