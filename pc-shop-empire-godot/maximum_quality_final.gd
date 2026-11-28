extends "res://maximum_quality_pass.gd"

# Screenshot-reviewed refinement pass. Fixes visual overflow/placeholder-looking details.

func _draw_environment_light_polish() -> void:
	var t := 0.035 + sin(mq_phase*1.7)*0.006
	if screen == "shop_floor":
		draw_circle(Vector2(690,270),245,Color(0.22,0.72,1.0,t))
		draw_circle(Vector2(1455,475),285,Color(0.90,0.04,0.18,t*0.75))
		draw_rect(Rect2(570,835,690,3),Color(0.20,0.72,1.0,0.08),true)
		# Proper compact shelf labels instead of empty decoration strips.
		var tags := [
			{"r":Rect2(510,392,150,24),"text":"GAMING"},
			{"r":Rect2(750,392,150,24),"text":"CREATOR"},
			{"r":Rect2(600,595,145,22),"text":"BEST VALUE"},
			{"r":Rect2(815,595,145,22),"text":"PREMIUM"}
		]
		for tag in tags:
			var r:Rect2 = tag.r
			draw_rect(r,Color(0.012,0.022,0.034,0.78),true)
			draw_rect(Rect2(r.position,Vector2(3,r.size.y)),Color(0.95,0.10,0.19,0.72),true)
			_txt(r.position+Vector2(12,16),String(tag.text),9,Color(0.80,0.87,0.94,0.84))
	else:
		draw_circle(Vector2(940,370),290,Color(0.15,0.70,1.0,t))
		draw_circle(Vector2(1420,680),245,Color(0.95,0.08,0.16,t*0.65))
		draw_rect(Rect2(530,540,830,3),Color(0.15,0.75,1.0,0.09),true)
		for i in range(6):
			var x := 590.0 + i*112.0
			draw_circle(Vector2(x,525),4.0,Color(0.18,0.95,0.68,0.58 if i%2==0 else 0.28))

func _draw_component_photo(dest:Rect2,cat:String,idx:int) -> void:
	# Bounded, category-specific thumbnail art: all geometry stays inside the product card.
	var tier:int = idx % 4
	var accents := [Color("#78889b"),Color("#26a9d8"),Color("#c83be9"),Color("#ef2948")]
	var a:Color = accents[tier]
	draw_rect(dest,Color("#0c141e"),true)
	draw_rect(dest,Color("#34475a"),false,2.0)
	var r:=dest.grow(-14.0)
	match cat:
		"CPU":
			var s:=minf(r.size.x,r.size.y)*0.56
			var q:=Rect2(r.get_center()-Vector2(s,s)*0.5,Vector2(s,s))
			draw_rect(q,Color("#bbc3ca"),true); draw_rect(q,Color("#68737f"),false,3.0)
			draw_rect(q.grow(-7),Color("#d5d9dd"),true)
			draw_rect(Rect2(q.position+Vector2(7,7),Vector2(q.size.x-14,5)),a,true)
		"Motherboard":
			var q:=Rect2(r.position+Vector2(38,4),Vector2(r.size.x-76,r.size.y-8))
			draw_rect(q,Color("#172127"),true); draw_rect(q,a.darkened(0.35),false,3.0)
			draw_rect(Rect2(q.position+Vector2(q.size.x*0.38,20),Vector2(40,35)),Color("#6c7884"),true)
			for n in range(4): draw_rect(Rect2(q.end.x-45+n*8,q.position.y+12,4,q.size.y-24),Color("#465669"),true)
			for n in range(2): draw_rect(Rect2(q.position+Vector2(22,q.end.y-q.position.y-24+n*9),Vector2(q.size.x-50,4)),Color("#556171"),true)
		"RAM":
			for n in range(2+(1 if tier>=2 else 0)):
				var q:=Rect2(r.position+Vector2(30+n*64,24),Vector2(48,r.size.y-48))
				draw_rect(q,Color("#17202a"),true); draw_rect(q,a,false,2.0); draw_rect(Rect2(q.position+Vector2(4,4),Vector2(q.size.x-8,6)),a,true)
		"GPU":
			var q:=Rect2(r.position+Vector2(18,18),Vector2(r.size.x-36,r.size.y-36))
			draw_rect(q,Color("#151e28"),true); draw_rect(q,a.darkened(0.25),false,3.0)
			var fans:=1+mini(tier,2)
			for n in range(fans):
				var c:=Vector2(q.position.x+q.size.x*(float(n)+0.5)/float(fans),q.get_center().y)
				var rad:=minf(24.0,q.size.y*0.30)
				draw_circle(c,rad,Color("#080c12")); draw_circle(c,rad*0.68,Color("#2a3542")); draw_circle(c,rad*0.16,a)
			draw_rect(Rect2(q.position+Vector2(8,6),Vector2(q.size.x-16,5)),a,true)
		"PSU":
			var q:=Rect2(r.position+Vector2(52,12),Vector2(r.size.x-104,r.size.y-24))
			draw_rect(q,Color("#111923"),true); draw_rect(q,Color("#526174"),false,3.0)
			draw_circle(q.get_center(),minf(q.size.x,q.size.y)*0.28,Color("#080c12")); draw_circle(q.get_center(),minf(q.size.x,q.size.y)*0.28,Color("#667585"),false,2.0)
		"Storage":
			var q:=Rect2(r.position+Vector2(35,30),Vector2(r.size.x-70,r.size.y-60))
			draw_rect(q,Color("#172329"),true); draw_rect(q,a.darkened(0.15),false,3.0)
			for n in range(5): draw_rect(Rect2(q.position+Vector2(20+n*34,10),Vector2(20,q.size.y-20)),Color("#2a3945"),true)
			draw_rect(Rect2(q.end.x-8,q.position.y+5,5,q.size.y-10),Color("#d5b45b"),true)
		"Cooling":
			if tier>=2:
				var rad:=Rect2(r.position+Vector2(18,16),Vector2(r.size.x-70,r.size.y-32))
				draw_rect(rad,Color("#171f28"),true); draw_rect(rad,a.darkened(0.30),false,3.0)
				for n in range(2): draw_circle(Vector2(rad.position.x+50+n*70,rad.get_center().y),25,Color("#283543"))
				draw_circle(Vector2(r.end.x-35,r.get_center().y),22,a.darkened(0.25)); draw_circle(Vector2(r.end.x-35,r.get_center().y),11,a)
			else:
				for n in range(4): draw_rect(Rect2(r.position+Vector2(65+n*15,14),Vector2(9,r.size.y-28)),Color("#596777"),true)
				draw_circle(r.get_center()+Vector2(25,0),30,Color("#222d39")); draw_circle(r.get_center()+Vector2(25,0),10,a)
		"Fans":
			for n in range(3):
				var c:=Vector2(r.position.x+58+n*78,r.get_center().y)
				draw_circle(c,32,Color("#111820")); draw_circle(c,25,Color("#2c3947")); draw_circle(c,9,a)
		"Case":
			# Retain the approved premium raster for the case category; frame/tier keeps cards distinct.
			super._draw_component_photo(dest,cat,idx)
		_:
			super._draw_component_photo(dest,cat,idx)
	var names := ["ENTRY","MID","HIGH","ENTHUSIAST"]
	draw_rect(Rect2(dest.position+Vector2(8,dest.size.y-20),Vector2(88,14)),Color(0.01,0.02,0.03,0.90),true)
	_txt(dest.position+Vector2(13,dest.size.y-8),names[tier],9,a)
