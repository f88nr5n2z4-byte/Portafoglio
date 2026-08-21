extends "res://beta_final.gd"

var controller_build_index := 0
var english_jobs := {
 "build_1440p":["1440p Gaming PC","Strong 1440p performance, stable and quiet."],
 "repair_boot":["PC will not power on","No sign of life when the power button is pressed."],
 "repair_heat":["Temperatures too high","Fans get loud and the PC slows down during games."],
 "upgrade_gpu":["1440p GPU upgrade","More FPS without replacing the whole computer."],
 "repair_ram":["Random crashes and BSOD","The PC restarts under load and reports random errors."],
 "storage_upgrade":["SSD and operating system","Slow boot: wants an SSD and a clean system install."],
 "build_creator":["Creator Workstation","Video editing, Blender and heavy multitasking."],
 "clean_service":["Cleaning and maintenance","Temperatures are rising and the PC is full of dust."],
 "build_fortnite":["High-refresh Fortnite PC","Aims at competitive high refresh without wasting budget."],
 "build_nvidia":["NVIDIA Gaming PC","Specifically wants a GeForce for 1440p Ultra."],
 "build_amd":["Balanced AMD build","Wants an all-AMD configuration with a good upgrade path."],
 "business_ssd":["Office SSD upgrade","Reception PC is slow: migrate to SSD and verify it."],
 "repair_storage":["Corrupted files and freezes","System freezes and some files are unreadable."],
 "repair_post":["No POST after upgrade","Added RAM and now the display stays black."],
 "build_silent":["Quiet Gaming PC","High performance without loud fans on the desk."],
 "upgrade_ram":["64 GB for virtual machines","Needs much more memory for VMs and containers."],
 "build_ai":["Local AI Workstation","Powerful machine for local inference and AI development."],
 "repair_gpu":["GPU artifacts under load","Desktop is normal but games show visual artifacts."]
}

func L(it:String,en:String) -> String:
	return en if language=="en" else it

func _job() -> Dictionary:
	var j:=super._job()
	if language!="en" or j.is_empty(): return j
	var id:=String(j.get("id",""))
	if not english_jobs.has(id): return j
	var d:=j.duplicate(true)
	var pair:Array=english_jobs[id]
	d["title"]=pair[0]; d["hint"]=pair[1]
	return d

func _required_level(c:Dictionary) -> int:
	var score:=float(c.get("score",0)); var price:=int(c.get("price",0))
	if price>=1000 or score>=105: return 4
	if price>=650 or score>=94: return 3
	if price>=400 or score>=86: return 2
	return 1

func _shop_components() -> Array:
	var raw:=components
	var out:=[]
	for c in raw:
		if _required_level(c)>level: continue
		if selected_shop_category=="Tutti" or String(c.category)==selected_shop_category: out.append(c)
	return out

func _input(event:InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and screen=="build":
		var owned:=_owned_components()
		if event.button_index==JOY_BUTTON_DPAD_UP and not owned.is_empty(): controller_build_index=posmod(controller_build_index-1,owned.size()); _beep(520); queue_redraw(); return
		if event.button_index==JOY_BUTTON_DPAD_DOWN and not owned.is_empty(): controller_build_index=posmod(controller_build_index+1,owned.size()); _beep(520); queue_redraw(); return
		if event.button_index==JOY_BUTTON_A and not owned.is_empty():
			controller_build_index=clamp(controller_build_index,0,owned.size()-1)
			_install_component(owned[controller_build_index]); queue_redraw(); return
		super._input(event); return
	super._input(event)

func _button(r:Rect2,label:String,active:=true) -> void:
	var mp:=get_viewport().get_mouse_position() if is_inside_tree() else Vector2(-100,-100)
	var hover:=active and r.has_point(mp)
	var pressed:=hover and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var fill:=Color("#1b2431") if hover else (Color("#151c28") if active else Color("#10141b"))
	if pressed: fill=Color("#28131a")
	_panel(r,fill,(CYAN if hover else RED) if active else Color("#323943"),3 if hover else 2)
	_txt(r.position+Vector2(24,r.size.y*0.64),label,22,WHITE if active else Color("#606b78"))

func _draw_online_shop() -> void:
	super._draw_online_shop()
	_txt(Vector2(1220,125),L("Snapshot prezzi 21/08/2026 • non quotazione live","Price snapshot 21 Aug 2026 • not a live quote"),14,MUTED)
	_txt(Vector2(380,175),L("Catalogo disponibile al livello %d"%level,"Catalog available at level %d"%level),16,CYAN)

func _draw_build() -> void:
	super._draw_build()
	var owned:=_owned_components()
	if not owned.is_empty():
		controller_build_index=clamp(controller_build_index,0,owned.size()-1)
		_txt(Vector2(1480,895),L("Controller: D-Pad scegli • A installa","Controller: D-Pad select • A install"),13,MUTED)
		var c:Dictionary=owned[controller_build_index]
		_txt(Vector2(1480,920),"▶ "+String(c.name),14,CYAN)

func _draw_settings() -> void:
	_draw_header(T("settings"))
	_panel(Rect2(420,135,1080,800),PANEL,Color("#37465b"))
	_txt(Vector2(485,182),L("VIDEO","VIDEO"),18,RED)
	var rows=[L("Risoluzione","Resolution"),L("Modalità schermo","Display mode"),"VSync",L("Limite FPS","FPS limit"),L("Qualità","Quality"),L("Lingua","Language"),"Master",L("Musica","Music"),L("Effetti","Effects"),"UI"]
	var vals=[settings.resolution,settings.window_mode,"ON" if settings.vsync else "OFF",(L("Illimitato","Unlimited") if int(settings.fps)==0 else str(settings.fps)),settings.quality,("Italiano" if language=="it" else "English"),"%d%%"%int(float(settings.master)*100),"%d%%"%int(float(settings.music)*100),"%d%%"%int(float(settings.sfx)*100),"%d%%"%int(float(settings.ui)*100)]
	for i in range(rows.size()):
		var y=205+i*67
		_txt(Vector2(500,y+35),rows[i],18,MUTED)
		_panel(Rect2(760,y,720,52),Color("#151d29"),Color("#303e52"))
		_txt(Vector2(1000,y+34),str(vals[i]),19,WHITE)
	_button(_btn(80,940,260,70),T("back"))

func _settings_click(p:Vector2) -> void:
	var rows=["resolution","window_mode","vsync","fps","quality","language","master","music","sfx","ui"]
	for i in range(rows.size()):
		if Rect2(760,205+i*67,720,52).has_point(p):
			var k=rows[i]
			match k:
				"resolution":
					var idx=resolutions.find(String(settings.resolution)); settings.resolution=resolutions[(idx+1)%resolutions.size()]
				"window_mode":
					var modes=["Windowed","Borderless","Fullscreen"]; var idx=modes.find(String(settings.window_mode)); settings.window_mode=modes[(idx+1)%modes.size()]
				"vsync": settings.vsync=not bool(settings.vsync)
				"fps":
					var fpss=[30,60,120,144,240,0]; var idx=fpss.find(int(settings.fps)); settings.fps=fpss[(idx+1)%fpss.size()]
				"quality":
					var idx=quality_levels.find(String(settings.quality)); settings.quality=quality_levels[(idx+1)%quality_levels.size()]
				"language": language="en" if language=="it" else "it"; settings.language=language
				_:
					settings[k]=fmod(float(settings[k])+0.25,1.25)
			_apply_video_settings(); _save_settings(); _beep(640); queue_redraw(); return
	if _btn(80,940,260,70).has_point(p): _save_settings(); screen=previous_screen; queue_redraw()

func _draw_controls() -> void:
	_draw_header(T("controls"))
	_panel(Rect2(330,160,1260,740),PANEL,Color("#3a485d"),3)
	_txt(Vector2(420,230),L("TASTIERA E MOUSE","KEYBOARD & MOUSE"),26,WHITE)
	var left=["WASD / Arrows","E","TAB / I","J","U","Mouse","ESC"]
	var right=[L("Movimento","Movement"),L("Interagisci","Interact"),L("Inventario","Inventory"),L("Lavori","Jobs"),L("Miglioramenti","Upgrades"),L("Drag & Drop / UI","Drag & Drop / UI"),L("Pausa / Indietro","Pause / Back")]
	for i in range(left.size()):
		var y=295+i*68; _txt(Vector2(430,y),left[i],20,CYAN); _txt(Vector2(800,y),right[i],20,WHITE)
	_txt(Vector2(420,800),"CONTROLLER",24,WHITE)
	_txt(Vector2(430,845),L("Stick: movimento • A: interazione/installazione • B: indietro • D-Pad: menu/banco","Stick: move • A: interact/install • B: back • D-Pad: menu/workbench"),17,MUTED)
	_button(_btn(80,940,260,70),T("back"))

func _draw_day_summary() -> void:
	_draw_header(L("RIEPILOGO GIORNATA","DAY SUMMARY"))
	_panel(Rect2(300,220,1320,620),PANEL,Color("#3a485b"))
	_txt(Vector2(400,310),L("Giorno %d completato"%day,"Day %d complete"%day),38,WHITE)
	var names=[L("Lavori completati totali","Total completed jobs"),L("Saldo","Balance"),L("Reputazione","Reputation"),L("Livello","Level")]
	var vals=[str(completed_jobs),"€ %d"%money,str(reputation),str(level)]
	for i in range(names.size()): _txt(Vector2(400,400+i*70),names[i],21,MUTED); _txt(Vector2(950,400+i*70),vals[i],28,GREEN if i==1 else (YELLOW if i==2 else WHITE))
	_button(_btn(1460,900,360,80),L("GIORNO SUCCESSIVO","NEXT DAY"))

func _draw_result() -> void:
	_draw_dim_bg(); _panel(Rect2(430,220,1060,640),Color("#0c121a"),GREEN,4)
	_txt(Vector2(690,320),L("LAVORO COMPLETATO","JOB COMPLETED"),42,GREEN)
	_txt(Vector2(650,410),L("Pagamento ricevuto","Payment received"),23,MUTED)
	_txt(Vector2(800,475),"€ %d"%money,42,WHITE)
	_txt(Vector2(650,555),L("Reputazione","Reputation")+": %d    "+L("Livello","Level")+": %d    XP: %d"%[reputation,level,xp],24,YELLOW)
	_txt(Vector2(610,680),L("Il cliente lascia il negozio soddisfatto.","The customer leaves the shop satisfied."),22,WHITE)
	_button(_btn(760,740,400,72),L("CONTINUA","CONTINUE"))
