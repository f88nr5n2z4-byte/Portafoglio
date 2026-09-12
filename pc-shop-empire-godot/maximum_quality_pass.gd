extends "res://milestone_a_final.gd"

# PC GAME EMPIRE — MAXIMUM QUALITY PASS
# Global presentation polish layered on top of the approved premium 2.5D direction.
# No redesign, no pixel-art conversion, no roadmap changes.

var mq_phase := 0.0
var mq_last_screen := ""
var mq_transition := 0.0

func _process(delta:float) -> void:
	mq_phase += delta
	if mq_last_screen != screen:
		mq_last_screen = screen
		mq_transition = 1.0
	mq_transition = maxf(0.0,mq_transition-delta*2.8)
	super._process(delta)

func _draw() -> void:
	super._draw()
	_draw_global_quality_overlay()

func _draw_global_quality_overlay() -> void:
	var edge := Color(0.0,0.0,0.0,0.10)
	draw_rect(Rect2(0,0,VW,22),edge,true)
	draw_rect(Rect2(0,VH-26,VW,26),Color(0,0,0,0.18),true)
	draw_rect(Rect2(0,0,22,VH),edge,true)
	draw_rect(Rect2(VW-22,0,22,VH),edge,true)
	draw_rect(Rect2(0,0,VW,2),Color(0.95,0.10,0.19,0.52),true)
	if screen in ["shop_floor","lab_floor"]:
		_draw_environment_light_polish()
	elif screen == "online_shop":
		_draw_shop_ui_polish()
	elif screen == "build":
		_draw_build_ui_polish()
	elif screen == "diagnostics":
		_draw_diagnostics_polish()
	elif screen == "menu":
		_draw_menu_polish()
	if mq_transition > 0.0:
		draw_rect(Rect2(0,0,VW,VH),Color(0.0,0.0,0.0,mq_transition*0.20),true)

func _draw_environment_light_polish() -> void:
	var t := 0.04 + sin(mq_phase*1.7)*0.008
	if screen == "shop_floor":
		draw_circle(Vector2(690,270),250,Color(0.22,0.72,1.0,t))
		draw_circle(Vector2(1455,475),300,Color(0.90,0.04,0.18,t*0.85))
		draw_rect(Rect2(570,835,690,5),Color(0.20,0.72,1.0,0.10),true)
		for r in [Rect2(510,392,210,24),Rect2(750,392,210,24),Rect2(600,595,190,22),Rect2(815,595,190,22)]:
			draw_rect(r,Color(0.015,0.025,0.038,0.74),true)
			draw_rect(Rect2(r.position,Vector2(4,r.size.y)),Color(0.95,0.10,0.19,0.75),true)
	else:
		draw_circle(Vector2(940,370),300,Color(0.15,0.70,1.0,t))
		draw_circle(Vector2(1420,680),260,Color(0.95,0.08,0.16,t*0.75))
		draw_rect(Rect2(530,540,830,5),Color(0.15,0.75,1.0,0.12),true)
		for i in range(6):
			var x := 590.0 + i*112.0
			draw_circle(Vector2(x,525),5.0,Color(0.18,0.95,0.68,0.70 if i%2==0 else 0.34))
		for i in range(5):
			draw_rect(Rect2(1215+i*46,705,22,62+i*5),Color(0.08,0.11,0.15,0.44),true)

func _draw_shop_ui_polish() -> void:
	_panel(Rect2(385,135,1475,54),Color(0.012,0.020,0.031,0.94),Color("#34475b"),2.0)
	_txt(Vector2(410,170),"CATALOGO HARDWARE",15,WHITE)
	_panel(Rect2(720,145,560,34),Color(0.025,0.035,0.052,0.94),Color("#27394b"),1.0)
	_txt(Vector2(742,168),"Cerca componente, serie o categoria…",13,MUTED)
	_txt(Vector2(1335,169),"FILTRI  •  PREZZO  •  COMPATIBILITÀ",12,CYAN)
	_panel(Rect2(385,882,1475,48),Color(0.012,0.019,0.029,0.95),Color("#29384a"),1.0)
	_txt(Vector2(410,913),"Artwork dedicato • stock • compatibilità • consegna",12,MUTED)
	_txt(Vector2(1560,913),"PC GAME EMPIRE SUPPLY",12,RED)

func _draw_build_ui_polish() -> void:
	_panel(Rect2(300,92,1130,44),Color(0.012,0.022,0.032,0.92),Color("#304357"),1.0)
	var status := "PRONTO" if _build_ready() else "IN LAVORAZIONE"
	var sc := GREEN if _build_ready() else YELLOW
	_txt(Vector2(330,121),"ASSEMBLAGGIO",13,WHITE)
	_txt(Vector2(480,121),status,13,sc)
	_txt(Vector2(1110,121),"Snap assistito • feedback compatibilità",12,MUTED)
	draw_line(Vector2(310,908),Vector2(1410,908),Color(0.18,0.72,1.0,0.20),2.0)

func _draw_diagnostics_polish() -> void:
	_panel(Rect2(310,128,1290,42),Color(0.012,0.022,0.032,0.92),Color("#304357"),1.0)
	_txt(Vector2(335,156),"DIAGNOSTICA ATTIVA",13,CYAN)
	_txt(Vector2(505,156),"POST • MEMORIA • STORAGE • TEMPERATURE • STRESS",12,MUTED)
	for i in range(5):
		var x := 1310.0+i*42.0
		draw_circle(Vector2(x,149),4.0,Color(0.20,0.95,0.65,0.55+0.20*sin(mq_phase*2.0+i)))

func _draw_menu_polish() -> void:
	draw_rect(Rect2(70,84,5,780),Color(0.95,0.08,0.18,0.56),true)
	draw_rect(Rect2(83,84,1,780),Color(0.25,0.70,1.0,0.22),true)
	_txt(Vector2(118,1015),"PREMIUM PC STORE SIMULATION",12,Color(0.75,0.82,0.90,0.72))
	_txt(Vector2(1640,1015),"BUILD • REPAIR • GROW",12,Color(0.75,0.82,0.90,0.72))

func _draw_hud() -> void:
	super._draw_hud()
	_panel(Rect2(1395,22,485,78),Color(0.010,0.017,0.026,0.92),Color("#324357"),2.0)
	_txt(Vector2(1420,53),"€ %d"%money,20,GREEN)
	_txt(Vector2(1560,53),"REP %d"%reputation,15,YELLOW)
	_txt(Vector2(1660,53),"LV %d"%level,15,CYAN)
	_txt(Vector2(1420,82),"GIORNO %d   •   %02d:%02d"%[day,int(hour),int((hour-floor(hour))*60.0)],12,MUTED)

func _draw_world_player(p:Vector2,in_lab:bool) -> void:
	# Keep the approved atlas character, improve grounding/integration rather than restyling it.
	draw_set_transform(p+Vector2(0,42),0.0,Vector2(1.0,0.34))
	draw_circle(Vector2.ZERO,46.0,Color(0,0,0,0.20))
	draw_circle(Vector2.ZERO,33.0,Color(0.10,0.55,0.92,0.07))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	super._draw_world_player(p,in_lab)
	var rim := 0.20+0.06*sin(mq_phase*2.5)
	draw_arc(p+Vector2(0,-28),58.0,PI*1.08,PI*1.92,18,Color(0.28,0.76,1.0,rim),2.0)

func _draw_world_customer(p:Vector2) -> void:
	draw_set_transform(p+Vector2(0,40),0.0,Vector2(1.0,0.35))
	draw_circle(Vector2.ZERO,42.0,Color(0,0,0,0.18))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	super._draw_world_customer(p)
	if current_job>=0:
		var pulse := 0.52+0.18*sin(mq_phase*4.2)
		draw_circle(p+Vector2(43,-94),25.0,Color(1.0,0.75,0.12,0.06+pulse*0.07))

func _draw_component_photo(dest:Rect2,cat:String,idx:int) -> void:
	# Product cards no longer reuse one generic crop: each category/slot gets a dedicated rendered variant.
	draw_rect(dest,Color("#0d141e"),true)
	draw_rect(dest,Color("#34475a"),false,2.0)
	var tier:int = idx % 4
	var fake := {
		"id":"catalog_%s_%d"%[cat,idx],
		"name":"%s SERIES %d"%[cat.to_upper(),idx+1],
		"category":cat,
		"score":55+tier*18,
		"price":120+tier*310+idx*17,
		"watts":500+tier*200,
		"kind":"aio" if cat=="Cooling" and tier>=2 else "air"
	}
	var r := dest.grow(-10.0)
	match cat:
		"Motherboard": _draw_motherboard_art(r,fake,_accent_for(fake))
		"CPU": _draw_cpu_art(r,fake,_accent_for(fake))
		"RAM": _draw_ram_art(r,fake,_accent_for(fake))
		"GPU": _draw_gpu_art(r,fake,_accent_for(fake))
		"PSU": _draw_psu_art(r,fake,_accent_for(fake))
		"Storage": _draw_storage_art(r,fake,_accent_for(fake))
		"Cooling": _draw_cooling_art(r,fake,_accent_for(fake))
		"Fans": _draw_fans_art(r,fake,_accent_for(fake))
		_:
			super._draw_component_photo(dest,cat,idx)
	# Tier signature makes budget-to-enthusiast progression immediately visible.
	var names := ["ENTRY","MID","HIGH","ENTHUSIAST"]
	var accents := [Color("#78889b"),Color("#26a9d8"),Color("#c83be9"),Color("#ef2948")]
	draw_rect(Rect2(dest.position+Vector2(8,dest.size.y-20),Vector2(88,14)),Color(0.01,0.02,0.03,0.86),true)
	_txt(dest.position+Vector2(13,dest.size.y-8),names[tier],9,accents[tier])

func _panel(r:Rect2,c:=PANEL,b:=Color("#2b3748"),width:=2.0) -> void:
	draw_rect(Rect2(r.position+Vector2(10,12),r.size),Color(0,0,0,0.22),true)
	draw_rect(Rect2(r.position+Vector2(5,6),r.size),Color(0,0,0,0.18),true)
	draw_rect(r,c,true)
	draw_rect(r,b,false,width)
	if r.size.x>70 and r.size.y>45:
		draw_line(r.position+Vector2(2,2),r.position+Vector2(r.size.x-2,2),Color(1,1,1,0.075),1.0)
		draw_line(r.position+Vector2(2,r.size.y-2),r.position+Vector2(r.size.x-2,r.size.y-2),Color(0,0,0,0.22),1.0)

func _button(r:Rect2,label:String,active:=true) -> void:
	var mp := get_local_mouse_position()
	var hover := active and r.has_point(mp)
	var pressed := hover and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var pulse := 0.5+0.5*sin(mq_phase*4.0)
	var fill := Color("#202b39") if hover else (Color("#111923") if active else Color("#0a0f15"))
	if pressed: fill = Color("#29151c")
	var edge := Color(1.0,0.26+0.08*pulse,0.37+0.08*pulse,1.0) if hover else (Color("#9d2038") if active else Color("#2a313b"))
	_panel(r,fill,edge,3.0 if hover else 2.0)
	if active:
		draw_rect(Rect2(r.position,Vector2(5,r.size.y)),Color("#ff274b") if hover else RED,true)
		if hover: draw_rect(r.grow(3.0),Color(1.0,0.10,0.22,0.10),false,2.0)
	_txt(r.position+Vector2(24,r.size.y*0.64),label,22,WHITE if active else Color("#59636f"))
