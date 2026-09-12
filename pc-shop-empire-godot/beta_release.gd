extends "res://beta_polish.gd"

var technician_tex := preload("res://assets/technician_25d.svg")
var customer_tex := preload("res://assets/customer_25d.svg")
var upgrades := {"Showroom":0,"Laboratorio":0,"Magazzino":0,"Brand":0}
var damaged_inventory := {}
var used_offers := []
var last_used_day := -1

func _ready() -> void:
	super._ready()
	var found := false
	for z in zones:
		if String(z.id)=="used": found=true
	if not found: zones.append({"id":"used","rect":Rect2(1280,690,480,190)})
	_refresh_used_offers()

func _process(delta: float) -> void:
	super._process(delta)
	if screen=="shop_floor": hour += delta*0.02
	if last_used_day != day: _refresh_used_offers()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and screen=="shop_floor":
		if event.keycode == KEY_U:
			screen="upgrades"; _beep(560); queue_redraw(); return
	if screen in ["used_market","upgrades"] and event.is_action_pressed("cancel"):
		screen="shop_floor"; queue_redraw(); return
	super._input(event)

func _interact_zone() -> void:
	if near_zone=="used":
		screen="used_market"; _beep(520); return
	super._interact_zone()

func _mouse_down(p: Vector2) -> void:
	if screen=="used_market": _used_click(p); return
	if screen=="upgrades": _upgrade_click(p); return
	if screen=="day_summary" and _btn(1460,900,360,80).has_point(p):
		var expense:=90+20*(int(upgrades.Showroom)+int(upgrades.Laboratorio)+int(upgrades.Magazzino)+int(upgrades.Brand))
		money=max(0,money-expense)
		day+=1; hour=8.0; screen="shop_floor"; _autosave(); _notify("Nuovo giorno • costi operativi €%d"%expense); return
	super._mouse_down(p)

func _draw() -> void:
	if screen=="used_market": _draw_used_market(); return
	if screen=="upgrades": _draw_upgrades(); return
	super._draw()

func _draw_player() -> void:
	var p:=player-Vector2(56,145)
	draw_texture_rect(technician_tex,Rect2(p,Vector2(112,154)),false)

func _draw_customer(p:Vector2) -> void:
	draw_texture_rect(customer_tex,Rect2(p-Vector2(52,137),Vector2(104,143)),false)
	if current_job>=0: _txt(p+Vector2(30,-75),"!",34,YELLOW)

func _draw_shop_environment() -> void:
	super._draw_shop_environment()
	_panel(Rect2(1280,690,480,190),Color(0.04,0.06,0.09,0.84),Color("#614838"),3)
	_txt(Vector2(1310,730),"USATO & OCCASIONI",18,YELLOW)
	for i in range(3):
		_panel(Rect2(1310+i*140,755,115,90),Color("#111722"),Color("#4c5260"))
		draw_circle(Vector2(1367+i*140,795),24,Color("#34243f") if i%2==0 else Color("#17394b"))
	_txt(Vector2(1330,870),"E • controlla offerte",14,MUTED)

func _draw_floor() -> void:
	super._draw_floor()
	if tutorial_step<10:
		_panel(Rect2(1450,150,410,365),Color(0.035,0.045,0.065,0.94),Color("#37475d"),2)
		_txt(Vector2(1480,190),"TUTORIAL",17,CYAN)
		var steps=["Muoviti nel negozio","Parla con il cliente","Accetta il lavoro","Esegui diagnosi se richiesta","Ordina i componenti","Attendi la consegna","Vai al laboratorio","Trascina i componenti","Testa il PC","Consegna e incassa"]
		for i in range(steps.size()):
			var done=tutorial_step>i
			_txt(Vector2(1480,230+i*27),("✓ " if done else "• ")+steps[i],14,GREEN if done else MUTED)
	_txt(Vector2(45,1030),"U • upgrade negozio",14,MUTED)

func _compatibility_reason(c:Dictionary) -> String:
	if int(damaged_inventory.get(String(c.id),0))>0:
		return "Componente guasto: diagnosticalo o sostituiscilo"
	return super._compatibility_reason(c)

func _online_shop_click(p:Vector2) -> void:
	if _btn(60,950,220,70).has_point(p): screen="shop_floor"; return
	var cats := ["Tutti","CPU","Motherboard","RAM","GPU","Storage","PSU","Case","Cooling","Fans"]
	for i in range(cats.size()):
		if Rect2(70,180+i*62,270,50).has_point(p): selected_shop_category=cats[i]; shop_scroll=0; return
	var list := _shop_components()
	for i in range(min(list.size(),8)):
		var c:Dictionary=list[i]
		var col:=i%4; var row:=i/4
		var r:=Rect2(390+col*365,210+row*330,325,285)
		if Rect2(r.position+Vector2(175,225),Vector2(130,46)).has_point(p):
			var price:=int(c.price)
			if money<price: _notify("Fondi insufficienti",false); return
			money-=price
			var delay: float = maxf(0.06,0.18-0.03*int(upgrades.Magazzino))
			pending_orders.append({"id":String(c.id),"name":String(c.name),"arrival_day":day,"arrival_hour":hour+delay})
			_notify("Ordine confermato • consegna %.0f min"%(delay*60.0))
			_beep(760,0.09,"sfx"); tutorial_step=max(tutorial_step,5); _autosave(); return

func _finish_job() -> void:
	var j:=_job()
	if j.is_empty(): return
	var base_reward:=int(j.reward)
	var bonus_rate:=0.05*int(upgrades.Showroom)+0.03*int(upgrades.Brand)
	var bonus:=int(base_reward*bonus_rate)
	var rep_bonus:=int(upgrades.Laboratorio)
	super._finish_job()
	if job_state=="none":
		money+=bonus; reputation+=rep_bonus
		if bonus>0 or rep_bonus>0: _notify("Bonus negozio: +€%d  +%d REP"%[bonus,rep_bonus])
		_autosave()

func _refresh_used_offers() -> void:
	last_used_day=day; used_offers.clear()
	var candidates:=[]
	for c in components:
		if String(c.category) in ["CPU","GPU","RAM","Storage"]: candidates.append(c)
	if candidates.is_empty(): return
	for i in range(min(4,candidates.size())):
		var c:Dictionary=candidates[(day*3+i*2)%candidates.size()]
		var risk:=0.15+0.2*((day+i)%4)
		used_offers.append({"id":String(c.id),"name":String(c.name),"price":int(float(c.price)*(0.45+0.08*i)),"risk":risk,"inspected":false,"fault":risk>=0.55})

func _used_click(p:Vector2) -> void:
	if _btn(60,950,220,70).has_point(p): screen="shop_floor"; return
	for i in range(used_offers.size()):
		var o:Dictionary=used_offers[i]; var r:=Rect2(180+i*420,260,360,480)
		if Rect2(r.position+Vector2(25,330),Vector2(145,58)).has_point(p):
			o.inspected=true; used_offers[i]=o; _beep(620,0.08,"sfx"); _notify("Controllo completato"); return
		if Rect2(r.position+Vector2(190,330),Vector2(145,58)).has_point(p):
			if money<int(o.price): _notify("Fondi insufficienti",false); return
			money-=int(o.price); var id:=String(o.id); inventory[id]=int(inventory.get(id,0))+1
			if bool(o.fault) and not bool(o.inspected): damaged_inventory[id]=int(damaged_inventory.get(id,0))+1
			used_offers.remove_at(i); _notify("Occasione acquistata" if not bool(o.fault) else ("Componente guasto acquistato" if not bool(o.inspected) else "Acquisto annullato: guasto noto"),not bool(o.fault)); _autosave(); return

func _draw_used_market() -> void:
	_draw_header("USATO & OCCASIONI")
	_txt(Vector2(120,155),"Prezzi bassi, ma gli articoli non ispezionati possono nascondere guasti.",20,MUTED)
	for i in range(used_offers.size()):
		var o:Dictionary=used_offers[i]; var r:=Rect2(180+i*420,260,360,480); _panel(r,PANEL,Color("#54463d"),3)
		draw_circle(r.position+Vector2(180,105),70,Color("#202838")); draw_circle(r.position+Vector2(180,105),48,Color("#5a2a65") if i%2==0 else Color("#1b5268"))
		_txt(r.position+Vector2(25,210),String(o.name),19,WHITE); _txt(r.position+Vector2(25,250),"€ %d"%int(o.price),27,GREEN)
		var status="NON ISPEZIONATO"
		var sc=YELLOW
		if bool(o.inspected): status="GUASTO" if bool(o.fault) else "FUNZIONANTE"; sc=RED if bool(o.fault) else GREEN
		_txt(r.position+Vector2(25,295),status,16,sc)
		_button(Rect2(r.position+Vector2(25,330),Vector2(145,58)),"ISPEZIONA")
		_button(Rect2(r.position+Vector2(190,330),Vector2(145,58)),"COMPRA",not (bool(o.inspected) and bool(o.fault)))
	_button(_btn(60,950,220,70),T("back"))

func _upgrade_click(p:Vector2) -> void:
	if _btn(60,950,220,70).has_point(p): screen="shop_floor"; return
	var names=["Showroom","Laboratorio","Magazzino","Brand"]
	for i in range(names.size()):
		var name=names[i]; var level_now=int(upgrades[name]); var r=Rect2(230+i*390,280,340,430)
		if Rect2(r.position+Vector2(45,330),Vector2(250,62)).has_point(p) and level_now<3:
			var costs=[600,1200,2500]; var cost=costs[level_now]
			if money<cost: _notify("Fondi insufficienti",false); return
			money-=cost; upgrades[name]=level_now+1; _notify(name+" migliorato al livello %d"%int(upgrades[name])); _beep(920,0.12,"sfx"); _autosave(); return

func _draw_upgrades() -> void:
	_draw_header("MIGLIORA PC GAME EMPIRE")
	_txt(Vector2(180,160),"Investi i profitti per aumentare margini, reputazione e velocità logistica.",20,MUTED)
	var names=["Showroom","Laboratorio","Magazzino","Brand"]
	var desc=["+5% ricavi per livello","+1 reputazione per lavoro","Consegne più rapide","+3% ricavi per livello"]
	for i in range(names.size()):
		var name=names[i]; var lv=int(upgrades[name]); var r=Rect2(230+i*390,280,340,430); _panel(r,PANEL,Color("#3a4657"),3)
		_txt(r.position+Vector2(30,65),name.to_upper(),22,WHITE); _txt(r.position+Vector2(30,115),"Livello %d / 3"%lv,19,CYAN); _txt(r.position+Vector2(30,170),desc[i],16,MUTED)
		for s in range(3): draw_rect(Rect2(r.position+Vector2(30+s*92,220),Vector2(72,12)),GREEN if s<lv else Color("#303744"),true)
		var label="MAX" if lv>=3 else "UPGRADE  € %d"%[600,1200,2500][lv]
		_button(Rect2(r.position+Vector2(45,330),Vector2(250,62)),label,lv<3)
	_button(_btn(60,950,220,70),T("back"))

func _save_game() -> void:
	super._save_game()
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); if not f: return
	var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY: return
	d["upgrades"]=upgrades; d["damaged_inventory"]=damaged_inventory; d["used_offers"]=used_offers; d["last_used_day"]=last_used_day
	var w:=FileAccess.open(SAVE_PATH,FileAccess.WRITE); if w: w.store_string(JSON.stringify(d))

func _load_game() -> void:
	super._load_game()
	if not FileAccess.file_exists(SAVE_PATH): return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); if not f: return
	var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY: return
	upgrades=d.get("upgrades",upgrades); damaged_inventory=d.get("damaged_inventory",{}); used_offers=d.get("used_offers",[]); last_used_day=int(d.get("last_used_day",-1))
	if used_offers.is_empty(): _refresh_used_offers()
