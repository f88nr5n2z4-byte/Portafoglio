extends "res://beta_runtime.gd"

var menu_bg := preload("res://assets/beta_menu_bg.svg")
var shop_bg := preload("res://assets/beta_shop_bg.svg")
var build_bg := preload("res://assets/beta_build_bg.svg")
var splash_time := 1.8
var controller_focus := 0
var pending_orders := []
var last_delivery_check := 0.0

func _ready() -> void:
	super._ready()
	screen = "splash"
	_apply_quality()
	queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	if screen == "splash":
		splash_time -= delta
		if splash_time <= 0.0:
			screen = "menu"
			queue_redraw()
	if screen == "shop_floor":
		var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if joy.length() > 0.22:
			player += joy.normalized() * speed * delta
			player.x = clamp(player.x,100.0,1810.0)
			player.y = clamp(player.y,150.0,970.0)
			player_dir = joy.normalized()
			hour += delta * 0.12
	_check_deliveries()

func _input(event: InputEvent) -> void:
	if screen == "splash":
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			splash_time = 0.0
		return
	if screen == "controls":
		if event.is_action_pressed("cancel"):
			screen = "pause" if previous_screen == "pause" else "settings"
			queue_redraw()
		return
	if event is InputEventJoypadButton and event.pressed:
		if screen == "menu":
			if event.button_index == JOY_BUTTON_DPAD_UP:
				controller_focus = posmod(controller_focus-1,6)
				_beep(540)
			elif event.button_index == JOY_BUTTON_DPAD_DOWN:
				controller_focus = posmod(controller_focus+1,6)
				_beep(540)
			elif event.button_index == JOY_BUTTON_A:
				_menu_click(Vector2(400,426+controller_focus*92))
			queue_redraw()
			return
	super._input(event)

func _mouse_down(p: Vector2) -> void:
	if screen == "controls":
		if _btn(80,940,260,70).has_point(p):
			screen = "pause" if previous_screen == "pause" else "settings"
			queue_redraw()
		return
	super._mouse_down(p)

func _pause_click(p: Vector2) -> void:
	var ys := [300,382,464,546,628,710,792]
	var acts := ["resume","save","load","settings","controls","menu","exit"]
	for i in range(ys.size()):
		if _btn(710,ys[i],500,62).has_point(p):
			match acts[i]:
				"resume": screen=previous_screen
				"save": _save_game(); _notify("Partita salvata")
				"load": _load_game()
				"settings": previous_screen="pause"; screen="settings"
				"controls": previous_screen="pause"; screen="controls"
				"menu": _autosave(); screen="menu"
				"exit": _autosave(); get_tree().quit()
			return

func _settings_click(p: Vector2) -> void:
	var before_quality := String(settings.quality)
	super._settings_click(p)
	if String(settings.quality) != before_quality:
		_apply_quality()

func _apply_quality() -> void:
	match String(settings.quality):
		"Low": get_viewport().msaa_2d = Viewport.MSAA_DISABLED
		"Medium": get_viewport().msaa_2d = Viewport.MSAA_2X
		"High": get_viewport().msaa_2d = Viewport.MSAA_4X
		"Ultra": get_viewport().msaa_2d = Viewport.MSAA_8X
		_: get_viewport().msaa_2d = Viewport.MSAA_4X

func _apply_video_settings() -> void:
	var s := String(settings.resolution).split("x")
	var target := Vector2i(1920,1080)
	if s.size()==2:
		target = Vector2i(int(s[0]),int(s[1]))
	var wm := String(settings.window_mode)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	if wm == "Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif wm == "Borderless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(target)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(settings.vsync) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(settings.fps)
	if is_inside_tree(): _apply_quality()

func _online_shop_click(p:Vector2) -> void:
	if _btn(60,950,220,70).has_point(p): screen="shop_floor"; return
	var cats := ["Tutti","CPU","Motherboard","RAM","GPU","Storage","PSU","Case","Cooling","Fans"]
	for i in range(cats.size()):
		if Rect2(70,180+i*62,270,50).has_point(p): selected_shop_category=cats[i]; shop_scroll=0; return
	var list := _shop_components()
	for i in range(min(list.size(),8)):
		var c:Dictionary=list[i]
		var col:=i%4
		var row:=i/4
		var r:=Rect2(390+col*365,210+row*330,325,285)
		if Rect2(r.position+Vector2(175,225),Vector2(130,46)).has_point(p):
			var price:=int(c.price)
			if money<price: _notify("Fondi insufficienti",false); return
			money-=price
			pending_orders.append({"id":String(c.id),"name":String(c.name),"arrival_day":day,"arrival_hour":hour+0.18})
			_notify("Ordine confermato: consegna in arrivo")
			_beep(760,0.09,"sfx")
			tutorial_step=max(tutorial_step,5)
			_autosave()
			return

func _check_deliveries() -> void:
	if pending_orders.is_empty(): return
	var delivered := []
	for o in pending_orders:
		if day > int(o.arrival_day) or (day == int(o.arrival_day) and hour >= float(o.arrival_hour)):
			var id := String(o.id)
			inventory[id] = int(inventory.get(id,0))+1
			delivered.append(o)
			_notify("Pacco consegnato: "+String(o.name))
			_beep(900,0.11,"sfx")
	for o in delivered: pending_orders.erase(o)
	if not delivered.is_empty(): _autosave()

func _save_game() -> void:
	super._save_game()
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f: return
	var d=JSON.parse_string(f.get_as_text())
	if typeof(d)!=TYPE_DICTIONARY: return
	d["pending_orders"] = pending_orders
	var w:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if w: w.store_string(JSON.stringify(d))

func _load_game() -> void:
	super._load_game()
	if not FileAccess.file_exists(SAVE_PATH): return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f: return
	var d=JSON.parse_string(f.get_as_text())
	if typeof(d)==TYPE_DICTIONARY: pending_orders=d.get("pending_orders",[])

func _draw() -> void:
	if screen == "splash":
		_draw_splash()
		return
	if screen == "controls":
		_draw_controls()
		return
	super._draw()

func _draw_splash() -> void:
	draw_texture_rect(menu_bg,Rect2(0,0,VW,VH),false)
	draw_rect(Rect2(0,0,VW,VH),Color(0.01,0.015,0.025,0.48))
	_txt(Vector2(690,470),"PC GAME",68,WHITE)
	_txt(Vector2(690,555),"EMPIRE",86,RED)
	_txt(Vector2(760,615),"BUILD • FIX • UPGRADE",19,MUTED)
	var progress:=clamp(1.0-splash_time/1.8,0.0,1.0)
	draw_rect(Rect2(680,700,560,6),Color("#252b35"),true)
	draw_rect(Rect2(680,700,560*progress,6),RED,true)

func _draw_neon_backdrop() -> void:
	draw_texture_rect(menu_bg,Rect2(0,0,VW,VH),false)
	draw_rect(Rect2(0,0,VW,VH),Color(0.01,0.015,0.025,0.18))

func _draw_shop_environment() -> void:
	draw_texture_rect(shop_bg,Rect2(0,0,VW,VH),false)
	# Dynamic interaction glows remain game-driven above the imported 2.5D environment.
	for z in zones:
		if String(z.id)==near_zone:
			var r:Rect2=z.rect
			draw_rect(r,Color(0.15,0.75,1.0,0.08),true)
			draw_rect(r,CYAN,false,3)

func _draw_case() -> void:
	draw_texture_rect(build_bg,Rect2(320,150,1080,790),false)
	for k in build_slots.keys():
		var c=_component(String(build_slots[k]))
		var r=_build_drop_rect(String(k))
		draw_rect(r,Color(0.2,0.75,0.85,0.10),true)
		draw_rect(r,CYAN,false,3)
		_txt(r.position+Vector2(12,28),String(c.name),14,WHITE)

func _draw_pause() -> void:
	_draw_dim_bg()
	_panel(Rect2(620,180,680,740),Color("#0a0f17"),RED,3)
	_txt(Vector2(790,250),"PAUSA",42,WHITE)
	var ls=[T("resume"),T("save"),T("load"),T("settings"),T("controls"),T("menu"),T("exit")]
	var ys=[300,382,464,546,628,710,792]
	for i in range(ls.size()): _button(_btn(710,ys[i],500,62),ls[i],i!=2 or FileAccess.file_exists(SAVE_PATH))

func _draw_controls() -> void:
	_draw_header(T("controls"))
	_panel(Rect2(330,160,1260,740),PANEL,Color("#3a485d"),3)
	_txt(Vector2(420,230),"TASTIERA E MOUSE",26,WHITE)
	var left=["WASD / Frecce","E","TAB / I","J","Mouse","ESC"]
	var right=["Movimento","Interagisci","Inventario","Lavori","Drag & Drop / UI","Pausa / Indietro"]
	for i in range(left.size()):
		var y=300+i*75
		_txt(Vector2(430,y),left[i],20,CYAN)
		_txt(Vector2(800,y),right[i],20,WHITE)
	_txt(Vector2(420,790),"CONTROLLER",24,WHITE)
	_txt(Vector2(430,840),"Stick sinistro: movimento   •   A: interazione   •   B: indietro/pausa   •   D-Pad: menu",18,MUTED)
	_button(_btn(80,940,260,70),T("back"))

func _draw_inventory() -> void:
	super._draw_inventory()
	if not pending_orders.is_empty():
		_panel(Rect2(1390,130,450,190),Color("#0d141d"),YELLOW,2)
		_txt(Vector2(1420,170),"ORDINI IN CONSEGNA",17,YELLOW)
		for i in range(min(pending_orders.size(),4)):
			var o=pending_orders[i]
			_txt(Vector2(1420,210+i*30),String(o.name),14,WHITE)
