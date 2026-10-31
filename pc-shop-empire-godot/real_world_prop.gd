extends Node2D

# Individual, reusable 2.5D world prop. Every furniture/product object is a real node.
var prop_kind := "shelf"
var prop_size := Vector2(180,100)
var accent := Color("#d7263d")
var label := ""
var variant := 0
var lit := true

func configure(kind:String,size:Vector2,text:String="",tone:Color=Color("#d7263d"),v:int=0) -> void:
	prop_kind=kind; prop_size=size; label=text; accent=tone; variant=v
	queue_redraw()

func _draw() -> void:
	match prop_kind:
		"floor_tile": _draw_floor_tile()
		"wall": _draw_wall()
		"counter": _draw_counter()
		"shelf": _draw_shelf()
		"display": _draw_display()
		"workbench": _draw_workbench()
		"cabinet": _draw_cabinet()
		"terminal": _draw_terminal()
		"door": _draw_door()
		"pc": _draw_pc()
		"box": _draw_box()
		"toolrack": _draw_toolrack()
		_: _draw_box()

func _iso_box(size:Vector2,height:float,front:Color,top:Color,side:Color,edge:Color=Color("#46576b")) -> void:
	var w:=size.x; var d:=size.y
	var top_poly:=PackedVector2Array([Vector2(-w/2,-height),Vector2(w/2,-height),Vector2(w/2+d*0.22,-height+d*0.24),Vector2(-w/2+d*0.22,-height+d*0.24)])
	draw_colored_polygon(top_poly,top)
	var front_poly:=PackedVector2Array([Vector2(-w/2,-height),Vector2(w/2,-height),Vector2(w/2,0),Vector2(-w/2,0)])
	draw_colored_polygon(front_poly,front)
	var side_poly:=PackedVector2Array([Vector2(w/2,-height),Vector2(w/2+d*0.22,-height+d*0.24),Vector2(w/2+d*0.22,d*0.24),Vector2(w/2,0)])
	draw_colored_polygon(side_poly,side)
	draw_polyline(PackedVector2Array([Vector2(-w/2,-height),Vector2(w/2,-height),Vector2(w/2+d*0.22,-height+d*0.24)]),edge,2.0)

func _draw_floor_tile() -> void:
	var r:=Rect2(-prop_size/2,prop_size)
	draw_rect(r,Color("#202833"),true)
	draw_rect(r,Color("#344454"),false,1.0)
	for x in range(int(r.position.x),int(r.end.x),64): draw_line(Vector2(x,r.position.y),Vector2(x,r.end.y),Color(1,1,1,0.025),1)
	for y in range(int(r.position.y),int(r.end.y),64): draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y),Color(0,0,0,0.08),1)

func _draw_wall() -> void:
	var r:=Rect2(-prop_size/2,prop_size)
	draw_rect(r,Color("#151c25"),true)
	draw_rect(r,Color("#39495b"),false,3)
	draw_line(Vector2(r.position.x,r.end.y-8),Vector2(r.end.x,r.end.y-8),accent.darkened(0.15),4)

func _draw_counter() -> void:
	_iso_box(prop_size,82,Color("#242d39"),Color("#364454"),Color("#111821"),Color("#627389"))
	draw_rect(Rect2(-prop_size.x*0.38,-70,prop_size.x*0.76,7),accent,true)
	if label!="": _label(Vector2(-prop_size.x*0.38,-43),label,13)

func _draw_shelf() -> void:
	_iso_box(prop_size,124,Color("#202a35"),Color("#344252"),Color("#111821"))
	for row in range(3):
		var y:float=-100+row*34
		draw_line(Vector2(-prop_size.x*0.43,y),Vector2(prop_size.x*0.43,y),Color("#657487"),3)
		for col in range(4):
			var x:float=-prop_size.x*0.37+col*(prop_size.x*0.24)
			var c:=accent.lightened(float((row+col+variant)%4)*0.07)
			draw_rect(Rect2(x,y-22,30,19),c.darkened(0.45),true)
			draw_rect(Rect2(x+3,y-19,24,4),c,true)
	if label!="": _label(Vector2(-prop_size.x*0.43,-76),label,11)

func _draw_display() -> void:
	_iso_box(prop_size,48,Color("#252f3b"),Color("#425163"),Color("#151c25"))
	var count:=3
	for i in range(count):
		var x:float=-prop_size.x*0.32+i*prop_size.x*0.32
		draw_line(Vector2(x,-76),Vector2(x,-49),Color("#75869a"),5)
		draw_rect(Rect2(x-39,-132,78,54),Color("#07111c"),true)
		draw_rect(Rect2(x-36,-129,72,48),Color(0.08,0.22,0.32,1),true)
		draw_rect(Rect2(x-33,-126,66,4),accent.lightened(i*0.08),true)
		draw_circle(Vector2(x,-104),11,Color(accent.r,accent.g,accent.b,0.28))
	if label!="": _label(Vector2(-prop_size.x*0.43,-20),label,11)

func _draw_workbench() -> void:
	_iso_box(prop_size,64,Color("#252b32"),Color("#454b52"),Color("#181c21"),Color("#7f8790"))
	# Anti-static mat
	draw_colored_polygon(PackedVector2Array([Vector2(-prop_size.x*0.32,-78),Vector2(prop_size.x*0.30,-78),Vector2(prop_size.x*0.37,-58),Vector2(-prop_size.x*0.25,-58)]),Color("#13353b"))
	# Open PC chassis
	draw_rect(Rect2(-55,-145,110,68),Color("#101720"),true); draw_rect(Rect2(-55,-145,110,68),Color("#68788a"),false,3)
	draw_rect(Rect2(-44,-136,76,48),Color("#172c30"),true)
	draw_circle(Vector2(37,-112),19,Color("#0b1118")); draw_circle(Vector2(37,-112),14,Color(accent.r,accent.g,accent.b,0.55))
	# Lamp
	draw_line(Vector2(prop_size.x*0.34,-66),Vector2(prop_size.x*0.34,-145),Color("#707b87"),7)
	draw_line(Vector2(prop_size.x*0.34,-145),Vector2(prop_size.x*0.18,-166),Color("#707b87"),6)
	draw_circle(Vector2(prop_size.x*0.17,-166),16,Color(0.86,0.95,1.0,0.85))
	if label!="": _label(Vector2(-prop_size.x*0.44,-30),label,12)

func _draw_cabinet() -> void:
	_iso_box(prop_size,150,Color("#252e38"),Color("#3c4856"),Color("#111821"))
	for i in range(4):
		var y:float=-130+i*33
		draw_rect(Rect2(-prop_size.x*0.40,y,prop_size.x*0.80,27),Color("#1a222c"),true)
		draw_line(Vector2(-7,y+14),Vector2(7,y+14),Color("#93a1b0"),2)
	if label!="": _label(Vector2(-prop_size.x*0.40,-112),label,10)

func _draw_terminal() -> void:
	_iso_box(prop_size,58,Color("#202b36"),Color("#3b4a59"),Color("#121923"))
	draw_rect(Rect2(-60,-145,120,76),Color("#060c13"),true); draw_rect(Rect2(-56,-141,112,68),Color("#102637"),true)
	draw_rect(Rect2(-50,-135,100,5),accent,true)
	draw_line(Vector2(0,-69),Vector2(0,-57),Color("#6f7b88"),6)
	draw_rect(Rect2(-46,-52,92,8),Color("#515e6c"),true)
	if label!="": _label(Vector2(-prop_size.x*0.42,-25),label,11)

func _draw_door() -> void:
	var r:=Rect2(-prop_size.x/2,-prop_size.y,prop_size.x,prop_size.y)
	draw_rect(r,Color("#202934"),true); draw_rect(r,Color("#75869a"),false,4)
	draw_rect(r.grow(-10),Color("#0d1823"),true)
	draw_rect(Rect2(r.position+Vector2(12,12),Vector2(r.size.x-24,8)),accent,true)
	draw_circle(Vector2(r.end.x-25,r.get_center().y),5,Color("#d6dde5"))
	if label!="": _label(Vector2(-prop_size.x*0.42,-18),label,10)

func _draw_pc() -> void:
	var w:=prop_size.x; var h:=prop_size.y
	_iso_box(Vector2(w,h*0.35),h*0.85,Color("#151c24"),Color("#303b47"),Color("#0b1016"))
	var window:=Rect2(-w*0.35,-h*0.76,w*0.52,h*0.55)
	draw_rect(window,Color(0.04,0.09,0.13,0.92),true); draw_rect(window,Color("#536577"),false,2)
	for i in range(3):
		var p:=Vector2(-w*0.22+i*w*0.17,-h*0.45)
		draw_circle(p,12,Color("#071018")); draw_circle(p,8,Color(accent.r,accent.g,accent.b,0.55))
	draw_rect(Rect2(-w*0.24,-h*0.68,w*0.30,10),accent.darkened(0.2),true)

func _draw_box() -> void:
	_iso_box(prop_size,52,Color("#34313a"),Color("#514854"),Color("#25232a"))
	draw_rect(Rect2(-prop_size.x*0.32,-39,prop_size.x*0.64,5),accent,true)
	if label!="": _label(Vector2(-prop_size.x*0.32,-18),label,9)

func _draw_toolrack() -> void:
	var r:=Rect2(-prop_size/2,prop_size)
	draw_rect(r,Color("#1b242d"),true); draw_rect(r,Color("#4d5e70"),false,3)
	for x in range(int(r.position.x+24),int(r.end.x-10),40):
		for y in range(int(r.position.y+20),int(r.end.y-10),30): draw_circle(Vector2(x,y),2,Color("#718093"))
	for i in range(6):
		var x:float=r.position.x+35+i*38
		draw_line(Vector2(x,r.position.y+38),Vector2(x,r.position.y+98+(i%2)*18),accent.lightened(i*0.035),5)
	if label!="": _label(Vector2(r.position.x+16,r.position.y+20),label,10)

func _label(pos:Vector2,text:String,size:int) -> void:
	draw_string(ThemeDB.fallback_font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("#e6edf5"))
