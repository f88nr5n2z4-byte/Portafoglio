extends "res://milestone_a.gd"

# PC GAME EMPIRE 1.0 — MILESTONE A COMPLETE PASS
# Premium 2.5D assembly presentation, accessible snap/drag UX and visual hardware tiers.

var install_fx_category := ""
var install_fx_time := 0.0
var install_fx_duration := 0.42
var invalid_drop_flash := 0.0

func _process(delta:float) -> void:
	install_fx_time = maxf(0.0,install_fx_time-delta)
	invalid_drop_flash = maxf(0.0,invalid_drop_flash-delta)
	super._process(delta)

func _install_component(c:Dictionary) -> void:
	var before:String = String(build_slots.get(String(c.get("category","")),""))
	super._install_component(c)
	var cat:String = String(c.get("category",""))
	if String(build_slots.get(cat,"")) == String(c.get("id","")) and String(c.get("id","")) != before:
		install_fx_category = cat
		install_fx_time = install_fx_duration
		_beep(960.0,0.08,"sfx")
		queue_redraw()

func _mouse_up(p:Vector2) -> void:
	if screen == "build" and dragging_id != "":
		var c:Dictionary = _component(dragging_id)
		if not c.is_empty():
			var cat:String = String(c.get("category",""))
			var target:Rect2 = _build_drop_rect(cat)
			if target.has_point(p):
				var reason:String = _compatibility_reason(c)
				if reason != "": invalid_drop_flash = 0.55
	super._mouse_up(p)

func _draw_build() -> void:
	super._draw_build()
	_draw_drag_feedback()
	_draw_assembly_legend()

func _draw_drag_feedback() -> void:
	if dragging_id == "": return
	var c:Dictionary = _component(dragging_id)
	if c.is_empty(): return
	var cat:String = String(c.get("category",""))
	var r:Rect2 = _build_drop_rect(cat)
	var reason:String = _compatibility_reason(c)
	var valid:bool = reason == ""
	var glow:Color = Color(0.25,1.0,0.62,0.18) if valid else Color(1.0,0.12,0.20,0.20)
	var border:Color = GREEN if valid else RED
	draw_rect(r.grow(8.0),glow,true)
	draw_rect(r.grow(4.0),border,false,4.0)
	var label:String = "RILASCIA QUI • SNAP" if valid else reason
	_panel(Rect2(r.position+Vector2(8,-44),Vector2(minf(520.0,maxf(240.0,r.size.x)),36)),Color(0.015,0.025,0.035,0.96),border,2.0)
	_txt(r.position+Vector2(18,-18),label,13,WHITE)
	if invalid_drop_flash > 0.0:
		draw_rect(Rect2(285,130,1145,800),Color(1.0,0.05,0.08,0.05+invalid_drop_flash*0.08),true)

func _draw_assembly_legend() -> void:
	_panel(Rect2(1455,100,410,58),Color(0.018,0.026,0.038,0.94),Color("#34475c"),2.0)
	_txt(Vector2(1475,126),"VERDE = compatibile",13,GREEN)
	_txt(Vector2(1655,126),"ROSSO = incompatibile",13,RED)
	_txt(Vector2(1475,149),"Trascina • snap • click destro rimuove",12,MUTED)

func _draw_case() -> void:
	# Keep the premium workbench/background from the approved visual pass.
	_draw_atlas_region(Rect2(290,135,1130,785),Rect2(0,360,640,445))
	draw_rect(Rect2(290,135,1130,785),Color(0,0,0,0.08),true)
	_draw_case_frame()
	var order:Array = ["Motherboard","PSU","Storage","CPU","RAM","GPU","Cooling","Fans"]
	for cat_var in order:
		var cat:String = String(cat_var)
		if not build_slots.has(cat): continue
		var c:Dictionary = _component(String(build_slots[cat]))
		_draw_installed_hardware(cat,c)
	if build_slots.has("Case") and not case_panel_open:
		_draw_closed_glass_panel()

func _draw_case_frame() -> void:
	var outer:=Rect2(345,185,930,700)
	draw_rect(outer,Color(0.025,0.035,0.05,0.72),true)
	draw_rect(outer,Color("#48586d"),false,5.0)
	draw_rect(Rect2(365,205,890,660),Color(0.02,0.028,0.04,0.42),true)
	# PSU shroud + rear slots + cable grommets.
	draw_rect(Rect2(390,720,820,120),Color("#111923"),true)
	draw_rect(Rect2(390,720,820,120),Color("#374659"),false,3.0)
	for i in range(6): draw_rect(Rect2(1125,565+i*22,72,12),Color("#263448"),true)
	for p in [Vector2(1050,315),Vector2(1050,520),Vector2(515,680)]:
		draw_circle(p,19,Color("#111822")); draw_circle(p,13,Color("#29374b"))
	if not build_slots.has("Motherboard"):
		_txt(Vector2(600,480),"AREA MOTHERBOARD",18,Color(0.7,0.78,0.88,0.45))

func _hardware_tier(c:Dictionary) -> int:
	var score:float = float(c.get("score",0.0))
	var price:int = int(c.get("price",0))
	if score >= 98.0 or price >= 900: return 3
	if score >= 86.0 or price >= 500: return 2
	if score >= 68.0 or price >= 220: return 1
	return 0

func _accent_for(c:Dictionary) -> Color:
	var tier:int = _hardware_tier(c)
	var accents:Array = [Color("#6e7e91"),Color("#26a9d8"),Color("#c83be9"),Color("#ef2948")]
	var base:Color = accents[tier]
	var h:int = abs(String(c.get("id","x")).hash())
	return base.lightened(float(h%12)/100.0)

func _draw_installed_hardware(cat:String,c:Dictionary) -> void:
	var r:Rect2 = _build_drop_rect(cat).grow(-12.0)
	var anim:float = 0.0
	if install_fx_category == cat and install_fx_time > 0.0:
		anim = install_fx_time/install_fx_duration
	var accent:Color = _accent_for(c)
	if anim > 0.0:
		draw_rect(r.grow(14.0*anim),Color(accent.r,accent.g,accent.b,0.10+0.18*anim),true)
		draw_rect(r.grow(8.0*anim),Color(accent.r,accent.g,accent.b,0.75*anim),false,4.0)
	match cat:
		"Motherboard": _draw_motherboard_art(r,c,accent)
		"CPU": _draw_cpu_art(r,c,accent)
		"RAM": _draw_ram_art(r,c,accent)
		"GPU": _draw_gpu_art(r,c,accent)
		"PSU": _draw_psu_art(r,c,accent)
		"Storage": _draw_storage_art(r,c,accent)
		"Cooling": _draw_cooling_art(r,c,accent)
		"Fans": _draw_fans_art(r,c,accent)
		_: pass
	_panel(Rect2(r.position+Vector2(4,4),Vector2(minf(260.0,r.size.x-8.0),30)),Color(0.01,0.02,0.03,0.88),accent,1.0)
	_txt(r.position+Vector2(12,26),String(c.get("name",cat)),11,WHITE)

func _draw_motherboard_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var q:=Rect2(r.position+Vector2(28,35),r.size-Vector2(56,58))
	draw_rect(q,Color("#151c22"),true); draw_rect(q,a.darkened(0.35),false,4.0)
	# PCB traces.
	for i in range(7):
		var yy:float=q.position.y+45+i*38
		draw_line(Vector2(q.position.x+30,yy),Vector2(q.end.x-35,yy+((i%2)*18)),Color(a.r,a.g,a.b,0.24),2.0)
	# CPU socket, RAM banks and PCIe slots.
	draw_rect(Rect2(q.position+Vector2(q.size.x*0.40,70),Vector2(115,105)),Color("#252d36"),true)
	draw_rect(Rect2(q.position+Vector2(q.size.x*0.40,70),Vector2(115,105)),Color("#7c8793"),false,3.0)
	for i in range(4): draw_rect(Rect2(q.end.x-105+i*18,q.position.y+55,10,210),Color("#39485a"),true)
	for i in range(3): draw_rect(Rect2(q.position.x+55,q.end.y-80+i*20,q.size.x-125,10),Color("#4a5564"),true)
	# VRM heatsinks depend on tier.
	var tier:int=_hardware_tier(c)
	for i in range(2+tier): draw_rect(Rect2(q.position+Vector2(22+i*38,24),Vector2(30,58)),a.darkened(0.45),true)

func _draw_cpu_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var s:float=minf(r.size.x,r.size.y)*0.58
	var q:=Rect2(r.get_center()-Vector2(s,s)*0.5,Vector2(s,s))
	draw_rect(q,Color("#b5bec7"),true); draw_rect(q,Color("#6e7781"),false,4.0)
	draw_rect(q.grow(-10),Color("#d4d8dc"),true)
	var tier:int=_hardware_tier(c)
	_txt(q.position+Vector2(12,q.size.y*0.58),["CORE E","CORE M","CORE X","CORE ULTRA"][tier],11,Color("#202733"))

func _draw_ram_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var tier:int=_hardware_tier(c)
	var sticks:int=2 if tier<2 else 4
	var gap:float=8.0
	var sw:float=maxf(16.0,(r.size.x-gap*(sticks+1))/float(sticks))
	for i in range(sticks):
		var q:=Rect2(r.position+Vector2(gap+i*(sw+gap),38),Vector2(sw,r.size.y-58))
		draw_rect(q,Color("#161e27"),true); draw_rect(q,a.darkened(0.15),false,2.0)
		for y in range(5): draw_rect(Rect2(q.position+Vector2(4,18+y*26),Vector2(q.size.x-8,11)),Color("#283444"),true)
		if tier>=1: draw_rect(Rect2(q.position+Vector2(3,3),Vector2(q.size.x-6,8)),a,true)

func _draw_gpu_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var tier:int=_hardware_tier(c)
	var q:=Rect2(r.position+Vector2(18,32),r.size-Vector2(36,48))
	draw_rect(q,Color("#171e27"),true); draw_rect(q,a.darkened(0.3),false,4.0)
	var fans:int=1+tier
	fans=min(fans,3)
	var radius:float=minf(q.size.y*0.34,q.size.x/(fans*2.7))
	for i in range(fans):
		var cx:float=q.position.x+q.size.x*(float(i)+0.5)/float(fans)
		var cy:float=q.get_center().y
		draw_circle(Vector2(cx,cy),radius,Color("#0b0f15"))
		draw_circle(Vector2(cx,cy),radius*0.72,Color("#26313e"))
		draw_circle(Vector2(cx,cy),radius*0.18,a)
		for blade in range(6):
			var ang:float=TAU*float(blade)/6.0
			draw_line(Vector2(cx,cy)+Vector2(cos(ang),sin(ang))*radius*0.25,Vector2(cx,cy)+Vector2(cos(ang+0.32),sin(ang+0.32))*radius*0.62,Color("#566170"),3.0)
	# Backplate / power connector detail.
	draw_rect(Rect2(q.position+Vector2(15,8),Vector2(q.size.x-30,10)),a.darkened(0.25),true)
	draw_rect(Rect2(q.end.x-38,q.position.y+8,22,15),Color("#d3aa4c"),true)

func _draw_psu_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var q:=Rect2(r.position+Vector2(25,36),r.size-Vector2(50,56))
	draw_rect(q,Color("#111821"),true); draw_rect(q,Color("#4b5867"),false,4.0)
	var center:=q.get_center(); var rad:=minf(q.size.x,q.size.y)*0.30
	draw_circle(center,rad,Color("#080c11")); draw_circle(center,rad,Color("#697585"),false,3.0)
	for i in range(8):
		var ang:float=TAU*float(i)/8.0
		draw_line(center,center+Vector2(cos(ang),sin(ang))*rad,Color("#3f4b59"),2.0)
	_txt(q.position+Vector2(12,q.size.y-12),"%dW"%int(c.get("watts",0)),15,a)

func _draw_storage_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var is_hdd:bool=String(c.get("name","")).to_lower().contains("hdd")
	var q:=Rect2(r.position+Vector2(18,38),r.size-Vector2(36,58))
	if is_hdd:
		draw_rect(q,Color("#c4c8cc"),true); draw_rect(q,Color("#68727d"),false,3.0)
		draw_circle(q.get_center(),minf(q.size.x,q.size.y)*0.27,Color("#707b86"))
		draw_circle(q.get_center(),minf(q.size.x,q.size.y)*0.08,Color("#d7dbdf"))
	else:
		draw_rect(q,Color("#152127"),true); draw_rect(q,a.darkened(0.15),false,3.0)
		for i in range(4): draw_rect(Rect2(q.position+Vector2(18+i*34,18),Vector2(25,q.size.y-36)),Color("#283641"),true)
		draw_rect(Rect2(q.end.x-18,q.position.y+8,10,q.size.y-16),Color("#d5b45b"),true)

func _draw_cooling_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var name:String=String(c.get("name","")).to_lower()
	var is_aio:bool=String(c.get("kind",""))=="aio" or name.contains("aio") or name.contains("galahad")
	if is_aio:
		var rad:=Rect2(r.position+Vector2(18,40),Vector2(r.size.x*0.34,r.size.y-65))
		draw_rect(rad,Color("#111820"),true); draw_rect(rad,Color("#485664"),false,3.0)
		for i in range(3): draw_circle(Vector2(rad.get_center().x,rad.position.y+35+i*(rad.size.y-70)/2.0),22,Color("#273341"))
		var pump:=Vector2(r.position.x+r.size.x*0.70,r.get_center().y)
		draw_circle(pump,48,Color("#111820")); draw_circle(pump,34,a.darkened(0.25)); draw_circle(pump,19,a)
		draw_line(rad.end-Vector2(0,25),pump+Vector2(-30,-15),Color("#313c48"),10.0)
		draw_line(rad.end-Vector2(0,55),pump+Vector2(-30,15),Color("#313c48"),10.0)
	else:
		var center:=r.get_center()
		for i in range(5): draw_rect(Rect2(center+Vector2(-65+i*8,-80),Vector2(55,160)),Color("#737e88"),true)
		draw_circle(center+Vector2(25,0),62,Color("#121820")); draw_circle(center+Vector2(25,0),48,Color("#344251")); draw_circle(center+Vector2(25,0),13,a)

func _draw_fans_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var count:int=3 if _hardware_tier(c)>=1 else 2
	for i in range(count):
		var center:=Vector2(r.get_center().x,r.position.y+(float(i)+0.5)*r.size.y/float(count))
		var radius:float=minf(38.0,r.size.y/float(count)*0.36)
		draw_circle(center,radius,Color("#111820")); draw_circle(center,radius*0.74,Color("#293746")); draw_circle(center,radius*0.18,a)

func _draw_closed_glass_panel() -> void:
	var glass:=Rect2(330,175,950,720)
	draw_rect(glass,Color(0.05,0.10,0.15,0.23),true)
	draw_rect(glass,Color(0.45,0.78,0.95,0.42),false,4.0)
	draw_line(glass.position+Vector2(80,40),glass.position+Vector2(360,40),Color(0.75,0.92,1.0,0.30),5.0)
	draw_line(glass.position+Vector2(110,55),glass.position+Vector2(600,55),Color(0.75,0.92,1.0,0.10),2.0)
	_txt(Vector2(690,870),"PANNELLO TEMPERED GLASS CHIUSO • PRONTO PER IL TEST",17,CYAN)
