extends "res://milestone_a_complete.gd"

# Final Milestone A polish. Keeps the approved premium 2.5D direction.
# Hardware families differ structurally by tier/design; no pixel-art or flat-icon fallback.

func _draw_case_frame() -> void:
	var outer:=Rect2(345,185,930,700)
	var case_c:Dictionary = _component(String(build_slots.get("Case","")))
	var tier:int = _hardware_tier(case_c) if not case_c.is_empty() else 0
	var accent:Color = _accent_for(case_c) if not case_c.is_empty() else Color("#56677b")
	var h:int = abs(String(case_c.get("id","empty")).hash())
	var shell:Color = Color("#101720") if tier<2 else Color("#0a1018")
	draw_rect(outer,shell,true)
	draw_rect(outer,accent.darkened(0.38),false,5.0)
	# Interior depth and rear tray.
	draw_rect(Rect2(365,205,890,660),Color(0.018,0.026,0.038,0.94),true)
	draw_rect(Rect2(380,220,850,625),Color(0.03,0.045,0.06,0.55),false,2.0)
	# Front intake styling varies per chassis family.
	var front_x:float = 1190.0
	if h % 3 == 0:
		for i in range(3):
			draw_circle(Vector2(front_x,310+i*145),52,Color("#0b1118")); draw_circle(Vector2(front_x,310+i*145),45,Color(accent.r,accent.g,accent.b,0.22),false,5.0)
	elif h % 3 == 1:
		for i in range(14): draw_line(Vector2(front_x-45,245+i*31),Vector2(front_x+45,245+i*31),Color("#364454"),3.0)
	else:
		draw_rect(Rect2(front_x-52,245,105,410),Color(0.08,0.13,0.18,0.65),true); draw_rect(Rect2(front_x-52,245,105,410),accent.darkened(0.25),false,3.0)
	# PSU shroud changes from plain to illuminated premium cover.
	draw_rect(Rect2(390,720,820,120),Color("#111923"),true)
	draw_rect(Rect2(390,720,820,120),Color("#374659"),false,3.0)
	if tier>=2:
		draw_line(Vector2(420,735),Vector2(920,735),Color(accent.r,accent.g,accent.b,0.72),4.0)
		_txt(Vector2(950,770),"PCGE",18,accent)
	# Expansion slots, cable grommets and case feet.
	for i in range(6): draw_rect(Rect2(1110,565+i*22,72,12),Color("#263448"),true)
	for p in [Vector2(1040,315),Vector2(1040,520),Vector2(515,680)]:
		draw_circle(p,19,Color("#0b1118")); draw_circle(p,12,Color("#2d3a4a"))
	draw_rect(Rect2(390,872,120,12),Color("#070b10"),true); draw_rect(Rect2(1090,872,120,12),Color("#070b10"),true)
	if not build_slots.has("Motherboard"):
		_txt(Vector2(600,480),"AREA MOTHERBOARD • DROP ZONE",18,Color(0.7,0.78,0.88,0.45))

func _draw_gpu_art(r:Rect2,c:Dictionary,a:Color) -> void:
	var tier:int=_hardware_tier(c)
	var h:int=abs(String(c.get("id","gpu")).hash())
	var q:=Rect2(r.position+Vector2(18,32),r.size-Vector2(36,48))
	# Different shroud silhouettes, not recolours.
	var body:=PackedVector2Array()
	if h % 3 == 0:
		body=PackedVector2Array([q.position+Vector2(0,12),q.position+Vector2(35,0),q.end-Vector2(20,q.size.y),q.end,q.position+Vector2(20,q.size.y)])
	elif h % 3 == 1:
		body=PackedVector2Array([q.position,q.end-Vector2(25,q.size.y),q.end,q.end-Vector2(0,18),q.position+Vector2(28,q.size.y),q.position+Vector2(0,q.size.y-35)])
	else:
		body=PackedVector2Array([q.position+Vector2(20,0),q.end-Vector2(0,q.size.y),q.end-Vector2(0,28),q.end-Vector2(22,0),q.position+Vector2(0,q.size.y),q.position+Vector2(0,25)])
	draw_colored_polygon(body,Color("#151c25")); draw_polyline(body, a.darkened(0.25),4.0)
	var fans:int = 1 if tier==0 else (2 if tier==1 else 3)
	if h%5==0 and tier>=2: fans=2
	var radius:float=minf(q.size.y*0.31,q.size.x/(fans*2.8))
	for i in range(fans):
		var cx:float=q.position.x+q.size.x*(float(i)+0.5)/float(fans)
		var cy:float=q.get_center().y+float((i%2)*8-4)
		draw_circle(Vector2(cx,cy),radius,Color("#080c11")); draw_circle(Vector2(cx,cy),radius*0.76,Color("#2b3744")); draw_circle(Vector2(cx,cy),radius*0.15,a)
		for blade in range(7):
			var ang:float=TAU*float(blade)/7.0
			draw_line(Vector2(cx,cy)+Vector2(cos(ang),sin(ang))*radius*0.22,Vector2(cx,cy)+Vector2(cos(ang+0.38),sin(ang+0.38))*radius*0.63,Color("#596675"),3.0)
	# Heatsink fins, PCIe fingers and power plug.
	for i in range(8+tier*3):
		var xx:float=q.position.x+18+i*(q.size.x-36)/float(8+tier*3)
		draw_line(Vector2(xx,q.position.y+8),Vector2(xx,q.position.y+18),Color("#778391"),2.0)
	draw_rect(Rect2(q.position.x+35,q.end.y-5,q.size.x*0.48,8),Color("#c7a94d"),true)
	draw_rect(Rect2(q.end.x-45,q.position.y+7,27,16),Color("#d0b05b"),true)
	if tier>=2: draw_line(q.position+Vector2(25,13),q.position+Vector2(q.size.x-65,13),Color(a.r,a.g,a.b,0.88),5.0)

func _draw_motherboard_art(r:Rect2,c:Dictionary,a:Color) -> void:
	super._draw_motherboard_art(r,c,a)
	var tier:int=_hardware_tier(c); var h:int=abs(String(c.get("id","mb")).hash())
	var q:=Rect2(r.position+Vector2(28,35),r.size-Vector2(56,58))
	# Model-specific heatsink geometry and debug display on premium boards.
	if h%2==0:
		draw_colored_polygon(PackedVector2Array([q.position+Vector2(12,12),q.position+Vector2(145,12),q.position+Vector2(125,72),q.position+Vector2(12,92)]),a.darkened(0.48))
	else:
		draw_rect(Rect2(q.position+Vector2(15,18),Vector2(128,52)),a.darkened(0.48),true)
	if tier>=2:
		draw_rect(Rect2(q.end.x-58,q.position.y+20,30,22),Color("#08121a"),true)
		_txt(q.end-Vector2(54,q.size.y-38),"88",12,a)
	if tier>=1: draw_line(q.position+Vector2(45,q.size.y-35),q.end-Vector2(120,35),Color(a.r,a.g,a.b,0.58),4.0)

func _draw_cooling_art(r:Rect2,c:Dictionary,a:Color) -> void:
	super._draw_cooling_art(r,c,a)
	var tier:int=_hardware_tier(c)
	if tier>=2:
		var pulse:float=0.55+0.15*sin(visual_phase*4.0)
		draw_circle(r.get_center(),minf(r.size.x,r.size.y)*0.12,Color(a.r,a.g,a.b,pulse),false,4.0)

func _draw_build() -> void:
	super._draw_build()
	# Clear, visual state for the two intentionally simplified operations.
	if thermal_paste_applied and build_slots.has("CPU"):
		var cr:Rect2=_build_drop_rect("CPU")
		draw_circle(cr.get_center()+Vector2(0,18),11,Color("#c9d2d7")); draw_circle(cr.get_center()+Vector2(0,18),5,Color("#eef3f5"))
		_txt(cr.position+Vector2(8,cr.size.y-8),"PASTA ✓",11,GREEN)
	if cables_connected and build_slots.has("Motherboard") and build_slots.has("PSU"):
		var mbc:Vector2=_build_drop_rect("Motherboard").get_center()
		var psuc:Vector2=_build_drop_rect("PSU").get_center()
		draw_polyline(PackedVector2Array([psuc,Vector2(psuc.x+115,psuc.y-25),Vector2(mbc.x-170,mbc.y+135),mbc]),Color("#202b39"),12.0)
		draw_polyline(PackedVector2Array([psuc,Vector2(psuc.x+115,psuc.y-25),Vector2(mbc.x-170,mbc.y+135),mbc]),Color("#8a2236"),3.0)
		_txt(Vector2(910,835),"CABLAGGIO PRINCIPALE ✓",12,GREEN)
