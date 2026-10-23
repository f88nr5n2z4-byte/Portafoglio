extends Node2D

const VW := 1920.0
const VH := 1080.0
const SAVE_PATH := "user://pc_game_empire_save.json"
const SETTINGS_PATH := "user://pc_game_empire_settings.json"
const BG := Color("#080b12")
const PANEL := Color("#111620")
const PANEL2 := Color("#171e2b")
const RED := Color("#ef233c")
const MAGENTA := Color("#d833ff")
const BLUE := Color("#28b7ff")
const CYAN := Color("#37e6e6")
const WHITE := Color("#f4f7fb")
const MUTED := Color("#9ba7b7")
const GREEN := Color("#5cf28b")
const YELLOW := Color("#ffd166")

var screen := "menu"
var previous_screen := "shop_floor"
var player := Vector2(910, 760)
var player_dir := Vector2.DOWN
var speed := 330.0
var money := 2000
var reputation := 0
var xp := 0
var level := 1
var day := 1
var hour := 8.0
var completed_jobs := 0
var current_job := -1
var job_state := "none"
var tutorial_step := 0
var language := "it"
var inventory := {}
var build_slots := {}
var diagnostics_done := []
var selected_shop_category := "Tutti"
var shop_scroll := 0
var dragging_id := ""
var drag_pos := Vector2.ZERO
var notification := ""
var notification_t := 0.0
var customers := []
var components := []
var jobs := []
var zones := [
 {"id":"customer","rect":Rect2(700,250,430,190)},
 {"id":"terminal","rect":Rect2(160,180,400,220)},
 {"id":"lab","rect":Rect2(1390,160,380,300)},
 {"id":"inventory","rect":Rect2(160,690,420,190)},
 {"id":"exit","rect":Rect2(820,930,300,100)}
]
var near_zone := ""
var settings := {
 "resolution":"1920x1080", "window_mode":"Windowed", "vsync":true, "fps":60,
 "quality":"High", "master":0.75, "music":0.35, "sfx":0.70, "ui":0.70, "ambient":0.30,
 "language":"it"
}
var resolutions := ["1280x720","1366x768","1600x900","1920x1080","2560x1440","3840x2160"]
var quality_levels := ["Low","Medium","High","Ultra"]
var music_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var music_phase := 0.0
var sfx_player: AudioStreamPlayer

var tr := {
 "it": {"new":"NUOVA PARTITA","continue":"CONTINUA","load":"CARICA PARTITA","settings":"IMPOSTAZIONI","credits":"CREDITI","exit":"ESCI","resume":"RIPRENDI","save":"SALVA","controls":"COMANDI","menu":"MENU PRINCIPALE","money":"DENARO","rep":"REPUTAZIONE","level":"LIVELLO","day":"GIORNO","objective":"OBIETTIVO","interact":"E  INTERAGISCI","shop":"NEGOZIO ONLINE","inventory":"INVENTARIO","jobs":"LAVORI","diagnostics":"DIAGNOSTICA","assembly":"ASSEMBLAGGIO","benchmark":"BENCHMARK","buy":"ACQUISTA","accept":"ACCETTA","reject":"RIFIUTA","back":"INDIETRO","complete":"COMPLETA","end_day":"CHIUDI GIORNATA"},
 "en": {"new":"NEW GAME","continue":"CONTINUE","load":"LOAD GAME","settings":"SETTINGS","credits":"CREDITS","exit":"EXIT","resume":"RESUME","save":"SAVE","controls":"CONTROLS","menu":"MAIN MENU","money":"MONEY","rep":"REPUTATION","level":"LEVEL","day":"DAY","objective":"OBJECTIVE","interact":"E  INTERACT","shop":"ONLINE SHOP","inventory":"INVENTORY","jobs":"JOBS","diagnostics":"DIAGNOSTICS","assembly":"ASSEMBLY","benchmark":"BENCHMARK","buy":"BUY","accept":"ACCEPT","reject":"REJECT","back":"BACK","complete":"COMPLETE","end_day":"END DAY"}
}

func _ready() -> void:
 _load_data()
 _load_settings()
 _setup_audio()
 _apply_video_settings()
 set_process(true)
 queue_redraw()

func _load_data() -> void:
 var cf := FileAccess.open("res://data/components.json", FileAccess.READ)
 if cf: components = JSON.parse_string(cf.get_as_text())
 var jf := FileAccess.open("res://data/jobs.json", FileAccess.READ)
 if jf: jobs = JSON.parse_string(jf.get_as_text())
 if components == null: components = []
 if jobs == null: jobs = []

func _setup_audio() -> void:
 music_player = AudioStreamPlayer.new()
 var mg := AudioStreamGenerator.new()
 mg.mix_rate = 22050
 mg.buffer_length = 0.5
 music_player.stream = mg
 add_child(music_player)
 music_player.play()
 music_playback = music_player.get_stream_playback()
 sfx_player = AudioStreamPlayer.new()
 add_child(sfx_player)

func _fill_music() -> void:
 if music_playback == null: return
 var frames := music_playback.get_frames_available()
 var vol := float(settings.master) * float(settings.music) * 0.035
 for i in range(frames):
  var sample := (sin(music_phase) + sin(music_phase * 0.503) * 0.35) * vol
  music_playback.push_frame(Vector2(sample,sample))
  music_phase += TAU * 72.0 / 22050.0
  if music_phase > TAU: music_phase -= TAU

func _beep(freq:=520.0, duration:=0.055, kind:="ui") -> void:
 var g := AudioStreamGenerator.new()
 g.mix_rate = 22050
 g.buffer_length = max(0.12,duration+0.04)
 sfx_player.stream = g
 sfx_player.play()
 var pb: AudioStreamGeneratorPlayback = sfx_player.get_stream_playback()
 var count := int(22050.0 * duration)
 var channel := float(settings.ui if kind == "ui" else settings.sfx)
 var amp := float(settings.master) * channel * 0.18
 for i in range(count):
  var env := 1.0 - float(i)/float(count)
  var v := sin(TAU * freq * float(i)/22050.0) * amp * env
  pb.push_frame(Vector2(v,v))

func _process(delta: float) -> void:
 _fill_music()
 if notification_t > 0:
  notification_t -= delta
  if notification_t <= 0: notification = ""
 if screen == "shop_floor":
  var d := Input.get_vector("move_left","move_right","move_up","move_down")
  if d.length() > 0.05:
   player += d.normalized()*speed*delta
   player.x = clamp(player.x,100.0,1810.0)
   player.y = clamp(player.y,150.0,970.0)
   player_dir = d.normalized()
   hour += delta * 0.12
  _update_near_zone()
 queue_redraw()

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("cancel"):
  if screen == "shop_floor": previous_screen = screen; screen = "pause"; _beep(360)
  elif screen == "pause": screen = previous_screen; _beep(500)
  elif screen not in ["menu","intro"]: screen = "shop_floor"; _beep(420)
  queue_redraw(); return
 if screen == "shop_floor" and event.is_action_pressed("interact"):
  _interact_zone(); return
 if event is InputEventKey and event.pressed and not event.echo:
  if screen == "shop_floor":
   if event.keycode == KEY_TAB or event.keycode == KEY_I: screen="inventory"
   elif event.keycode == KEY_J: screen="jobs"
  elif screen == "build" and event.keycode == KEY_B and _build_ready(): screen="benchmark"
  queue_redraw()
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed: _mouse_down(event.position)
  else: _mouse_up(event.position)
 if event is InputEventMouseMotion and dragging_id != "": drag_pos = event.position; queue_redraw()

func _mouse_down(p: Vector2) -> void:
 _beep(580,0.035,"ui")
 match screen:
  "menu": _menu_click(p)
  "pause": _pause_click(p)
  "settings": _settings_click(p)
  "credits": if _btn(80,920,260,70).has_point(p): screen="menu"
  "job_offer": _job_offer_click(p)
  "jobs": if _btn(70,930,240,70).has_point(p): screen="shop_floor"
  "inventory": if _btn(70,930,240,70).has_point(p): screen="shop_floor"
  "online_shop": _online_shop_click(p)
  "diagnostics": _diagnostics_click(p)
  "build": _build_mouse_down(p)
  "benchmark": if _btn(1460,900,360,80).has_point(p) and _build_ready(): _finish_job()
  "day_summary": if _btn(1460,900,360,80).has_point(p): day += 1; hour=8.0; screen="shop_floor"; _autosave(); _notify("Nuovo giorno iniziato")
 queue_redraw()

func _mouse_up(p: Vector2) -> void:
 if screen == "build" and dragging_id != "":
  var c := _component(dragging_id)
  if not c.is_empty():
   var cat := String(c.category)
   var z := _build_drop_rect(cat)
   if z.has_point(p): _install_component(c)
   else: _notify("Rilascia il componente nello slot evidenziato", false)
  dragging_id = ""
  queue_redraw()

func _menu_click(p:Vector2) -> void:
 var items := ["continue","new","load","settings","credits","exit"]
 for i in range(items.size()):
  if _btn(150,390+i*92,500,72).has_point(p):
   match items[i]:
    "continue": if FileAccess.file_exists(SAVE_PATH): _load_game()
    "new": _new_game()
    "load": if FileAccess.file_exists(SAVE_PATH): _load_game()
    "settings": previous_screen="menu"; screen="settings"
    "credits": screen="credits"
    "exit": get_tree().quit()

func _pause_click(p:Vector2) -> void:
 var ys := [330,420,510,600,690,780]
 var acts := ["resume","save","load","settings","menu","exit"]
 for i in range(ys.size()):
  if _btn(710,ys[i],500,66).has_point(p):
   match acts[i]:
    "resume": screen=previous_screen
    "save": _save_game(); _notify("Partita salvata")
    "load": _load_game()
    "settings": previous_screen="pause"; screen="settings"
    "menu": _autosave(); screen="menu"
    "exit": _autosave(); get_tree().quit()

func _new_game() -> void:
 money=2000; reputation=0; xp=0; level=1; day=1; hour=8.0; completed_jobs=0
 current_job=0 if jobs.size()>0 else -1; job_state="offered"; tutorial_step=0
 inventory.clear(); build_slots.clear(); diagnostics_done.clear(); player=Vector2(910,760)
 screen="intro"; _save_game();

func _interact_zone() -> void:
 match near_zone:
  "customer":
   if current_job < 0: _offer_next_job()
   elif job_state == "offered": screen="job_offer"
   elif job_state == "accepted":
    if String(_job().get("type","")) == "repair":
     screen="diagnostics"
    else:
     screen="jobs"
   elif job_state == "ready": _finish_job()
   else: _notify("Il lavoro è ancora in corso")
  "terminal": screen="online_shop"
  "lab":
   if current_job >= 0 and job_state in ["accepted","working"]: screen="build"
   else: _notify("Non hai un lavoro attivo",false)
  "inventory": screen="inventory"
  "exit": screen="day_summary"

func _update_near_zone() -> void:
 near_zone=""; var best:=99999.0
 for z in zones:
  var r:Rect2=z.rect
  var q:=Vector2(clamp(player.x,r.position.x,r.end.x),clamp(player.y,r.position.y,r.end.y))
  var dist:=player.distance_to(q)
  if dist<75 and dist<best: best=dist; near_zone=z.id

func _offer_next_job() -> void:
 if jobs.is_empty(): return
 current_job = completed_jobs % jobs.size(); job_state="offered"; diagnostics_done.clear(); build_slots.clear(); screen="job_offer"

func _job() -> Dictionary:
 if current_job>=0 and current_job<jobs.size(): return jobs[current_job]
 return {}

func _job_offer_click(p:Vector2) -> void:
 if _btn(1120,820,320,78).has_point(p):
  job_state="accepted"; tutorial_step=max(tutorial_step,2); _notify("Lavoro accettato"); _autosave(); screen="shop_floor"
 elif _btn(1470,820,320,78).has_point(p):
  current_job=-1; job_state="none"; _notify("Lavoro rifiutato",false); screen="shop_floor"

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
   money-=price; inventory[c.id]=int(inventory.get(c.id,0))+1; _notify("Acquistato: %s"%c.name); _beep(760,0.09,"sfx"); tutorial_step=max(tutorial_step,5); _autosave(); return

func _shop_components() -> Array:
 if selected_shop_category=="Tutti": return components
 var out:=[]
 for c in components:
  if String(c.category)==selected_shop_category: out.append(c)
 return out

func _diagnostics_click(p:Vector2) -> void:
 if _btn(70,930,240,70).has_point(p): screen="shop_floor"; return
 var j:=_job(); if j.is_empty(): return
 var tests:Array=j.get("tests",["Visual","POST","Temperatures","Stress"])
 for i in range(tests.size()):
  if _btn(180,300+i*100,500,72).has_point(p):
   var test=String(tests[i])
   if test not in diagnostics_done: diagnostics_done.append(test); _beep(620,0.08,"sfx"); _notify("Test completato: "+test)
   tutorial_step=max(tutorial_step,4); return
 if _btn(1260,820,470,80).has_point(p) and _diagnosis_revealed():
  job_state="working"; _notify("Diagnosi confermata: "+String(j.get("fault","Manutenzione"))); screen="online_shop"

func _diagnosis_revealed() -> bool:
 var j:=_job(); var tests:Array=j.get("tests",[])
 return diagnostics_done.size() >= max(1,tests.size()-1)

func _build_mouse_down(p:Vector2) -> void:
 if _btn(70,930,240,70).has_point(p): screen="shop_floor"; return
 if _btn(1500,930,300,70).has_point(p) and _build_ready(): screen="benchmark"; return
 var owned:=_owned_components()
 for i in range(min(owned.size(),9)):
  var r:=Rect2(1480,170+i*82,360,68)
  if r.has_point(p): dragging_id=String(owned[i].id); drag_pos=p; _beep(500,0.05,"sfx"); return

func _owned_components() -> Array:
 var out:=[]
 for c in components:
  if int(inventory.get(c.id,0))>0: out.append(c)
 return out

func _build_drop_rect(cat:String) -> Rect2:
 var map={"Motherboard":Rect2(480,260,600,400),"CPU":Rect2(650,350,150,120),"RAM":Rect2(820,330,150,210),"GPU":Rect2(560,610,620,130),"Storage":Rect2(1010,350,180,140),"PSU":Rect2(430,700,270,150),"Case":Rect2(350,190,900,700),"Cooling":Rect2(600,300,250,250),"Fans":Rect2(1120,250,120,420)}
 return map.get(cat,Rect2(350,190,900,700))

func _install_component(c:Dictionary) -> void:
 var reason:=_compatibility_reason(c)
 if reason!="": _notify(reason,false); _beep(180,0.12,"sfx"); return
 var cat:=String(c.category)
 if cat=="Fans": cat="Fans"
 if build_slots.has(cat):
  var oldid=String(build_slots[cat]); inventory[oldid]=int(inventory.get(oldid,0))+1
 build_slots[cat]=c.id
 inventory[c.id]=max(0,int(inventory.get(c.id,0))-1)
 job_state="working"; tutorial_step=max(tutorial_step,7); _notify("Installato: "+String(c.name)); _beep(880,0.10,"sfx"); _autosave()

func _compatibility_reason(c:Dictionary) -> String:
 var cat:=String(c.category)
 if cat=="CPU" and build_slots.has("Motherboard"):
  var mb:=_component(String(build_slots.Motherboard))
  if String(c.get("socket",""))!=String(mb.get("socket","")): return "CPU incompatibile: socket differente"
 if cat=="Motherboard" and build_slots.has("CPU"):
  var cpu:=_component(String(build_slots.CPU))
  if String(c.get("socket",""))!=String(cpu.get("socket","")): return "Scheda madre incompatibile con la CPU"
 if cat=="RAM" and build_slots.has("Motherboard"):
  var mb2:=_component(String(build_slots.Motherboard))
  if String(c.get("ram",""))!=String(mb2.get("ram","")): return "RAM incompatibile con la scheda madre"
 if cat=="GPU" and build_slots.has("Case"):
  var ca:=_component(String(build_slots.Case))
  if int(c.get("length",0))>int(ca.get("gpu_max",999)): return "GPU troppo lunga per il case"
 if cat=="Cooling" and build_slots.has("CPU"):
  var cp:=_component(String(build_slots.CPU)); var sockets:Array=c.get("sockets",[])
  if String(cp.get("socket","")) not in sockets: return "Dissipatore incompatibile con il socket"
 if cat=="PSU" and build_slots.has("GPU"):
  var gp:=_component(String(build_slots.GPU)); var need:=int(gp.get("power",0))+350
  if int(c.get("watts",0))<need: return "Alimentatore insufficiente: servono almeno %dW"%need
 return ""

func _build_ready() -> bool:
 var j:=_job(); if j.is_empty(): return false
 if String(j.type)=="repair":
  var fault:=String(j.get("fault",""))
  if fault=="Dust": return diagnostics_done.size()>0
  var category := "PSU" if fault=="PSU" else ("RAM" if fault=="RAM" else ("Cooling" if fault=="Cooling" else fault))
  return build_slots.has(category)
 var needs:Array=j.get("need",[])
 for n in needs:
  if not build_slots.has(String(n)): return false
 return true

func _component(id:String) -> Dictionary:
 for c in components:
  if String(c.id)==id: return c
 return {}

func _finish_job() -> void:
 var j:=_job(); if j.is_empty(): return
 if not _build_ready() and String(j.type)!="repair": _notify("Il lavoro non è completo",false); return
 var reward:=int(j.reward); money+=reward; reputation+=int(j.rep); xp+=int(j.xp); completed_jobs+=1
 level=1+int(xp/500); job_state="done"; tutorial_step=max(tutorial_step,10)
 _notify("Lavoro completato: +€%d"%reward); _beep(980,0.18,"sfx"); current_job=-1; job_state="none"; build_slots.clear(); diagnostics_done.clear(); _autosave(); screen="result"

func _save_game() -> void:
 var data={"money":money,"reputation":reputation,"xp":xp,"level":level,"day":day,"hour":hour,"completed_jobs":completed_jobs,"current_job":current_job,"job_state":job_state,"tutorial_step":tutorial_step,"inventory":inventory,"build_slots":build_slots,"diagnostics":diagnostics_done,"player":[player.x,player.y]}
 var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE); if f: f.store_string(JSON.stringify(data))

func _autosave() -> void: _save_game(); _save_settings()
func _load_game() -> void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var f:=FileAccess.open(SAVE_PATH,FileAccess.READ); var d=JSON.parse_string(f.get_as_text()); if typeof(d)!=TYPE_DICTIONARY: return
 money=int(d.get("money",2000)); reputation=int(d.get("reputation",0)); xp=int(d.get("xp",0)); level=int(d.get("level",1)); day=int(d.get("day",1)); hour=float(d.get("hour",8.0)); completed_jobs=int(d.get("completed_jobs",0)); current_job=int(d.get("current_job",-1)); job_state=String(d.get("job_state","none")); tutorial_step=int(d.get("tutorial_step",0)); inventory=d.get("inventory",{}); build_slots=d.get("build_slots",{}); diagnostics_done=d.get("diagnostics",[])
 var pp=d.get("player",[910,760]); player=Vector2(float(pp[0]),float(pp[1])); screen="shop_floor"; _notify("Partita caricata")

func _save_settings() -> void:
 settings.language=language
 var f:=FileAccess.open(SETTINGS_PATH,FileAccess.WRITE); if f: f.store_string(JSON.stringify(settings))
func _load_settings() -> void:
 if FileAccess.file_exists(SETTINGS_PATH):
  var f:=FileAccess.open(SETTINGS_PATH,FileAccess.READ); var d=JSON.parse_string(f.get_as_text()); if typeof(d)==TYPE_DICTIONARY:
   for k in d: settings[k]=d[k]
 language=String(settings.get("language","it"))

func _apply_video_settings() -> void:
 var s:=String(settings.resolution).split("x"); if s.size()==2: DisplayServer.window_set_size(Vector2i(int(s[0]),int(s[1])))
 var wm:=String(settings.window_mode)
 if wm=="Fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
 elif wm=="Borderless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
 else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(settings.vsync) else DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=int(settings.fps)

func _settings_click(p:Vector2) -> void:
 var rows=["resolution","window_mode","vsync","fps","quality","language","master","music","sfx","ui","ambient"]
 for i in range(rows.size()):
  if Rect2(760,195+i*67,720,52).has_point(p):
   var k=rows[i]
   match k:
    "resolution": var idx=resolutions.find(String(settings.resolution)); settings.resolution=resolutions[(idx+1)%resolutions.size()]
    "window_mode": var modes=["Windowed","Borderless","Fullscreen"]; var idx=modes.find(String(settings.window_mode)); settings.window_mode=modes[(idx+1)%modes.size()]
    "vsync": settings.vsync=not bool(settings.vsync)
    "fps": var fpss=[30,60,120,144,240,0]; var idx=fpss.find(int(settings.fps)); settings.fps=fpss[(idx+1)%fpss.size()]
    "quality": var idx=quality_levels.find(String(settings.quality)); settings.quality=quality_levels[(idx+1)%quality_levels.size()]
    "language": language="en" if language=="it" else "it"; settings.language=language
    _:
     settings[k]=fmod(float(settings[k])+0.25,1.25)
   _apply_video_settings(); _save_settings(); _beep(640); return
 if _btn(80,940,260,70).has_point(p): _save_settings(); screen=previous_screen

func _notify(text:String,good:=true) -> void: notification=text; notification_t=3.0
func T(k:String) -> String: return String(tr.get(language,tr.it).get(k,k))
func _btn(x:float,y:float,w:float,h:float)->Rect2: return Rect2(x,y,w,h)
func _font(): return ThemeDB.fallback_font
func _txt(p:Vector2,s:String,size:=24,col:=WHITE): draw_string(_font(),p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)
func _panel(r:Rect2,c:=PANEL,b:=Color("#2b3748"),width:=2.0): draw_rect(r,c,true); draw_rect(r,b,false,width)
func _button(r:Rect2,label:String,active:=true): _panel(r,Color("#151c28") if active else Color("#10141b"),RED if active else Color("#323943"),2); _txt(r.position+Vector2(24,r.size.y*0.64),label,22,WHITE if active else Color("#606b78"))

func _draw() -> void:
 draw_rect(Rect2(0,0,VW,VH),BG)
 match screen:
  "menu": _draw_menu()
  "intro": _draw_intro()
  "shop_floor": _draw_floor()
  "job_offer": _draw_job_offer()
  "online_shop": _draw_online_shop()
  "inventory": _draw_inventory()
  "jobs": _draw_jobs()
  "diagnostics": _draw_diagnostics()
  "build": _draw_build()
  "benchmark": _draw_benchmark()
  "pause": _draw_pause()
  "settings": _draw_settings()
  "credits": _draw_credits()
  "day_summary": _draw_day_summary()
  "result": _draw_result()
 if notification!="":
  _panel(Rect2(650,35,620,62),Color("#151b23"),CYAN,2); _txt(Vector2(680,76),notification,21,WHITE)

func _draw_menu() -> void:
 _draw_neon_backdrop(); _txt(Vector2(150,180),"PC GAME",58,WHITE); _txt(Vector2(150,250),"EMPIRE",76,RED); _txt(Vector2(155,292),"BUILD  •  FIX  •  UPGRADE  •  EMPIRE",18,MUTED)
 var labels=[T("continue"),T("new"),T("load"),T("settings"),T("credits"),T("exit")]
 for i in range(labels.size()): _button(_btn(150,390+i*92,500,72),labels[i],i not in [0,2] or FileAccess.file_exists(SAVE_PATH))
 _txt(Vector2(1480,1010),"BETA 0.5 NATIVE",17,MUTED)

func _draw_neon_backdrop() -> void:
 for i in range(14):
  var x=850+i*82; draw_line(Vector2(x,120),Vector2(x-430,980),Color(0.9,0.05,0.18,0.08),3)
 for i in range(10): draw_circle(Vector2(1050+i*75,220+(i%3)*190),80,Color(0.1,0.2,0.5,0.08))
 _panel(Rect2(900,170,780,650),Color("#0c1018"),Color("#2c1628"),3)
 for i in range(4):
  var r=Rect2(980+i*155,360,120,240); _panel(r,Color("#101722"),Color("#402039")); draw_circle(r.position+Vector2(60,70),38,Color("#7428a6")); draw_circle(r.position+Vector2(60,165),38,Color("#1b7ca8"))

func _draw_intro() -> void:
 _draw_neon_backdrop(); _panel(Rect2(370,250,1180,570),Color(0.04,0.05,0.08,0.96),RED,3); _txt(Vector2(460,350),"PC GAME EMPIRE",52,WHITE); _txt(Vector2(460,425),"Hai investito i tuoi ultimi €2.000 per aprire il tuo negozio PC.",28,MUTED); _txt(Vector2(460,485),"Ripara. Assembla. Guadagna reputazione. Espandi l'impero.",25,WHITE); _button(_btn(680,650,560,86),"ENTRA NEL NEGOZIO")
 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): pass

func _draw_floor() -> void:
 _draw_shop_environment(); _draw_hud(); _draw_player();
 if near_zone!="": _button(_btn(800,880,320,62),T("interact"))
 _panel(Rect2(45,150,360,170),Color(0.04,0.05,0.075,0.94),Color("#39465a")); _txt(Vector2(70,188),T("objective"),16,MUTED); _txt(Vector2(70,230),_objective_text(),22,WHITE); _txt(Vector2(70,275),"WASD • E • TAB/I • J • ESC",16,MUTED)

func _draw_shop_environment() -> void:
 var floor_poly=PackedVector2Array([Vector2(100,140),Vector2(1820,140),Vector2(1780,960),Vector2(140,960)])
 draw_colored_polygon(floor_poly,Color("#20242c"))
 for y in range(160,960,80): draw_line(Vector2(120,y),Vector2(1800,y),Color("#303640"),2)
 for x in range(160,1800,120): draw_line(Vector2(x,150),Vector2(x-25,950),Color("#2c323b"),2)
 _txt(Vector2(710,122),"PC GAME EMPIRE",36,WHITE); draw_line(Vector2(600,135),Vector2(1320,135),RED,5)
 _iso_counter(Rect2(670,250,460,170),"BANCO CLIENTI",RED)
 _iso_counter(Rect2(150,180,410,210),"COMPONENT SHOP",MAGENTA)
 _iso_counter(Rect2(1390,160,380,300),"LABORATORIO",BLUE)
 _iso_counter(Rect2(160,690,420,190),"MAGAZZINO",CYAN)
 for i in range(3): _pc_display(Vector2(650+i*230,570),i)
 for i in range(5):
  var pos=Vector2(190+i*285,470); _panel(Rect2(pos,Vector2(185,90)),Color("#111722"),Color("#313a4a")); draw_rect(Rect2(pos+Vector2(25,16),Vector2(135,58)),Color("#152c4a")); draw_line(pos+Vector2(35,60),pos+Vector2(145,28),Color("#7942ff"),3)
 draw_rect(Rect2(820,940,280,25),Color("#0e1117")); _txt(Vector2(850,932),"USCITA / CHIUSURA",14,MUTED)
 _draw_customer(Vector2(900,460))

func _iso_counter(r:Rect2,label:String,accent:Color) -> void:
 draw_rect(r,Color("#11151c"),true); draw_rect(r,Color("#3b4655"),false,3)
 var side=PackedVector2Array([r.position+Vector2(r.size.x,r.size.y),r.position+Vector2(r.size.x+22,r.size.y-18),r.position+Vector2(r.size.x+22,18),r.position+Vector2(r.size.x,0)])
 draw_colored_polygon(side,Color("#090c11")); draw_line(r.position+Vector2(0,r.size.y-6),r.position+Vector2(r.size.x,r.size.y-6),accent,5); _txt(r.position+Vector2(24,40),label,18,WHITE)

func _pc_display(p:Vector2,i:int) -> void:
 _panel(Rect2(p,Vector2(170,220)),Color("#0d1118"),Color("#343c49")); draw_circle(p+Vector2(85,72),48,Color("#341b48") if i%2==0 else Color("#113f59")); draw_circle(p+Vector2(85,72),31,MAGENTA if i%2==0 else BLUE); draw_rect(Rect2(p+Vector2(32,132),Vector2(106,12)),Color("#252d3a")); _txt(p+Vector2(34,190),"GAMING PC",15,MUTED)

func _draw_player() -> void:
 draw_set_transform(player+Vector2(0,30),0,Vector2(1,0.42)); draw_circle(Vector2.ZERO,30,Color(0,0,0,0.35)); draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_rect(Rect2(player-Vector2(24,22),Vector2(48,60)),Color("#10151e")); draw_line(player+Vector2(-22,0),player+Vector2(22,0),RED,5); draw_circle(player-Vector2(0,38),19,Color("#d5a07d")); draw_arc(player-Vector2(0,43),20,PI,TAU,20,Color("#191416"),8)

func _draw_customer(p:Vector2) -> void:
 draw_set_transform(p+Vector2(0,27),0,Vector2(1,0.42)); draw_circle(Vector2.ZERO,27,Color(0,0,0,0.32)); draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_rect(Rect2(p-Vector2(22,20),Vector2(44,58)),Color("#274a36")); draw_circle(p-Vector2(0,37),18,Color("#d3a17d")); if current_job>=0: _txt(p+Vector2(30,-50),"!",34,YELLOW)

func _draw_hud() -> void:
 _panel(Rect2(25,22,1870,92),Color(0.03,0.04,0.06,0.96),Color("#293344")); _txt(Vector2(55,62),"PC GAME EMPIRE",23,WHITE); _txt(Vector2(55,92),"€ %d"%money,24,GREEN); _txt(Vector2(1220,64),"%s  ★ %d"%[T("rep"),reputation],19,YELLOW); _txt(Vector2(1450,64),"%s %d   %d XP"%[T("level"),level,xp],19,WHITE); _txt(Vector2(1700,64),"%s %d"%[T("day"),day],18,WHITE); _txt(Vector2(1700,92),"%02d:%02d"%[int(hour),int(fmod(hour,1.0)*60)],18,MUTED)

func _objective_text() -> String:
 if tutorial_step<2: return "Parla con il primo cliente"
 if current_job<0: return "Attendi il prossimo cliente"
 if job_state=="offered": return "Valuta la richiesta del cliente"
 if String(_job().type)=="repair" and not _diagnosis_revealed(): return "Diagnostica il PC"
 if not _build_ready(): return "Acquista e installa i componenti"
 return "Esegui benchmark e consegna"

func _draw_job_offer() -> void:
 _draw_dim_bg(); var j:=_job(); _panel(Rect2(160,150,1600,780),Color("#0c111a"),Color("#39475a"),3); _txt(Vector2(220,220),String(j.customer),38,YELLOW); _txt(Vector2(220,280),String(j.title),42,WHITE); _txt(Vector2(220,350),String(j.hint),25,MUTED); _txt(Vector2(220,440),"Budget: € %d"%int(j.budget),26,GREEN); _txt(Vector2(220,490),"Ricompensa: € %d   +%d REP   +%d XP"%[int(j.reward),int(j.rep),int(j.xp)],25,WHITE); _button(_btn(1120,820,320,78),T("accept")); _button(_btn(1470,820,320,78),T("reject"))

func _draw_online_shop() -> void:
 _draw_header(T("shop")); var cats=["Tutti","CPU","Motherboard","RAM","GPU","Storage","PSU","Case","Cooling","Fans"]
 _panel(Rect2(45,145,310,780),Color("#0e131c"),Color("#273346")); for i in range(cats.size()):
  var rr=Rect2(70,180+i*62,270,50); if selected_shop_category==cats[i]: draw_rect(rr,Color("#31121b"),true); _txt(rr.position+Vector2(16,33),cats[i],18,RED if selected_shop_category==cats[i] else WHITE)
 var list:=_shop_components(); for i in range(min(list.size(),8)):
  var c:Dictionary=list[i]; var col:=i%4; var row:=i/4; var r:=Rect2(390+col*365,210+row*330,325,285); _panel(r,Color("#101722"),Color("#2f3a4a")); draw_circle(r.position+Vector2(162,75),48,Color("#172844")); _txt(r.position+Vector2(20,150),String(c.name),18,WHITE); _txt(r.position+Vector2(20,184),String(c.category),15,MUTED); _txt(r.position+Vector2(20,222),"€ %d"%int(c.price),22,GREEN); _button(Rect2(r.position+Vector2(175,225),Vector2(130,46)),T("buy"))
 _txt(Vector2(1500,110),"SALDO € %d"%money,24,GREEN); _button(_btn(60,950,220,70),T("back"))

func _draw_inventory() -> void:
 _draw_header(T("inventory")); var owned:=_owned_components(); _txt(Vector2(90,160),"Componenti posseduti: %d"%owned.size(),20,MUTED); for i in range(owned.size()):
  var c:Dictionary=owned[i]; var col=i%4; var row=i/4; var r=Rect2(90+col*445,220+row*160,400,125); _panel(r,PANEL2,Color("#39465a")); _txt(r.position+Vector2(20,40),String(c.name),18,WHITE); _txt(r.position+Vector2(20,76),String(c.category),15,MUTED); _txt(r.position+Vector2(310,76),"x%d"%int(inventory.get(c.id,0)),22,GREEN)
 if owned.is_empty(): _txt(Vector2(760,520),"Inventario vuoto",30,MUTED)
 _button(_btn(70,930,240,70),T("back"))

func _draw_jobs() -> void:
 _draw_header(T("jobs")); var j:=_job(); if j.is_empty(): _txt(Vector2(700,480),"Nessun lavoro attivo",30,MUTED)
 else:
  _panel(Rect2(120,200,1680,550),PANEL,Color("#3b4658")); _txt(Vector2(180,270),String(j.customer)+" — "+String(j.title),34,WHITE); _txt(Vector2(180,330),"Stato: "+job_state.to_upper(),22,YELLOW); _txt(Vector2(180,390),String(j.hint),22,MUTED); _txt(Vector2(180,470),"Ricompensa € %d"%int(j.reward),25,GREEN); _txt(Vector2(180,530),"Diagnostica: %s"%(", ".join(diagnostics_done) if not diagnostics_done.is_empty() else "—"),19,MUTED); _txt(Vector2(180,590),"Componenti installati: %d"%build_slots.size(),20,WHITE)
 _button(_btn(70,930,240,70),T("back"))

func _draw_diagnostics() -> void:
 _draw_header(T("diagnostics")); var j:=_job(); _panel(Rect2(100,160,740,760),PANEL,Color("#39475b")); _txt(Vector2(160,220),String(j.title),30,WHITE); _txt(Vector2(160,270),String(j.hint),19,MUTED); var tests:Array=j.get("tests",["Visual","POST","Temperatures","Stress"]); for i in range(tests.size()):
  var done=String(tests[i]) in diagnostics_done; _button(_btn(180,300+i*100,500,72),("✓ " if done else "▶ ")+String(tests[i]));
 _panel(Rect2(900,160,900,760),Color("#0b111a"),Color("#2c394c")); _txt(Vector2(960,225),"MONITOR DIAGNOSTICO",26,CYAN); _txt(Vector2(960,300),"POST",18,MUTED); _txt(Vector2(1210,300),"OK" if "POST" in diagnostics_done else "—",18,GREEN if "POST" in diagnostics_done else MUTED); _txt(Vector2(960,350),"CPU TEMP",18,MUTED); _txt(Vector2(1210,350),"92°C" if _diagnosis_revealed() and String(j.get("fault",""))=="Cooling" else "64°C",20,RED if _diagnosis_revealed() and String(j.get("fault",""))=="Cooling" else GREEN); _txt(Vector2(960,400),"MEMORY",18,MUTED); _txt(Vector2(1210,400),"ERRORS" if _diagnosis_revealed() and String(j.get("fault",""))=="RAM" else "PASS",20,RED if _diagnosis_revealed() and String(j.get("fault",""))=="RAM" else GREEN); if _diagnosis_revealed(): _txt(Vector2(960,570),"Probabile guasto: "+String(j.get("fault","Manutenzione")),28,YELLOW); _button(_btn(1260,820,470,80),"CONFERMA DIAGNOSI")
 _button(_btn(70,930,240,70),T("back"))

func _draw_build() -> void:
 _draw_header(T("assembly")); _panel(Rect2(320,150,1080,790),Color("#0d1118"),Color("#536174"),4); _txt(Vector2(380,200),"BANCO ASSEMBLAGGIO — DRAG & DROP",20,MUTED); _draw_case(); _panel(Rect2(1450,130,420,820),PANEL,Color("#38455a")); _txt(Vector2(1490,178),"COMPONENTI DISPONIBILI",20,WHITE); var owned:=_owned_components(); for i in range(min(owned.size(),9)):
  var c:Dictionary=owned[i]; var r=Rect2(1480,170+i*82,360,68); _panel(r,Color("#151c27"),Color("#303b4c")); _txt(r.position+Vector2(14,28),String(c.name),15,WHITE); _txt(r.position+Vector2(14,53),String(c.category)+"  x%d"%int(inventory.get(c.id,0)),13,MUTED)
 if dragging_id!="": var c=_component(dragging_id); _panel(Rect2(drag_pos-Vector2(130,35),Vector2(260,70)),Color("#21151d"),RED,3); _txt(drag_pos-Vector2(112,-8),String(c.name),15,WHITE)
 _button(_btn(70,930,240,70),T("back")); _button(_btn(1500,930,300,70),"TEST PC",_build_ready())

func _draw_case() -> void:
 var case=Rect2(390,240,900,620); _panel(case,Color("#080b10"),Color("#555f6c"),5); draw_rect(Rect2(430,280,760,470),Color("#111824"),true); _panel(Rect2(500,320,510,330),Color("#171e28"),Color("#3e4b5a")); _txt(Vector2(680,500),"MOTHERBOARD",18,MUTED)
 for k in build_slots.keys():
  var c=_component(String(build_slots[k])); var r=_build_drop_rect(String(k)); draw_rect(r,Color(0.2,0.75,0.85,0.12),true); draw_rect(r,CYAN,false,3); _txt(r.position+Vector2(12,28),String(c.name),14,WHITE)
 draw_circle(Vector2(1140,350),62,Color("#1b2330")); draw_circle(Vector2(1140,350),46,Color("#293a50")); draw_line(Vector2(1080,760),Vector2(1230,760),RED,5)

func _draw_benchmark() -> void:
 _draw_header(T("benchmark")); _panel(Rect2(120,170,1680,760),Color("#0c111a"),Color("#3d4b60"),3); _txt(Vector2(180,235),"PC GAME EMPIRE PERFORMANCE SUITE",30,WHITE); var score:=_build_score(); _txt(Vector2(180,320),"STABILITÀ",18,MUTED); _txt(Vector2(550,320),"PASS",24,GREEN); _txt(Vector2(180,375),"CPU TEMP",18,MUTED); _txt(Vector2(550,375),"67°C",24,GREEN); _txt(Vector2(180,430),"GPU TEMP",18,MUTED); _txt(Vector2(550,430),"71°C",24,GREEN); _txt(Vector2(180,485),"RUMOROSITÀ",18,MUTED); _txt(Vector2(550,485),"29 dB",24,GREEN); _txt(Vector2(900,310),"1440p GAMING — stima simulata",20,MUTED); _txt(Vector2(900,370),"Fortnite       %d FPS"%int(score*2.15),25,WHITE); _txt(Vector2(900,425),"Warzone        %d FPS"%int(score*1.45),25,WHITE); _txt(Vector2(900,480),"Cyberpunk      %d FPS"%int(score*0.88),25,WHITE); _txt(Vector2(900,535),"Blender Index  %d"%int(score*10),25,WHITE); _txt(Vector2(180,720),"RISULTATO: PC STABILE E PRONTO ALLA CONSEGNA",30,GREEN); _button(_btn(1460,900,360,80),"CONSEGNA AL CLIENTE")

func _build_score() -> float:
 var s:=70.0; for k in build_slots:
  var c=_component(String(build_slots[k])); s+=float(c.get("score",0))*0.25
 return clamp(s,70.0,220.0)

func _draw_pause() -> void:
 _draw_dim_bg(); _panel(Rect2(620,210,680,680),Color("#0a0f17"),RED,3); _txt(Vector2(780,280),"PAUSA",42,WHITE); var ls=[T("resume"),T("save"),T("load"),T("settings"),T("menu"),T("exit")]; var ys=[330,420,510,600,690,780]; for i in range(ls.size()): _button(_btn(710,ys[i],500,66),ls[i],i!=2 or FileAccess.file_exists(SAVE_PATH))

func _draw_settings() -> void:
 _draw_header(T("settings")); _panel(Rect2(420,135,1080,800),PANEL,Color("#37465b")); var rows=["Risoluzione","Modalità schermo","VSync","Limite FPS","Qualità","Lingua","Master","Musica","Effetti","UI","Ambiente"]; var vals=[settings.resolution,settings.window_mode,"ON" if settings.vsync else "OFF",("Illimitato" if int(settings.fps)==0 else str(settings.fps)),settings.quality,("Italiano" if language=="it" else "English"),"%d%%"%int(float(settings.master)*100),"%d%%"%int(float(settings.music)*100),"%d%%"%int(float(settings.sfx)*100),"%d%%"%int(float(settings.ui)*100),"%d%%"%int(float(settings.ambient)*100)]; for i in range(rows.size()):
  var y=195+i*67; _txt(Vector2(500,y+35),rows[i],18,MUTED); _panel(Rect2(760,y,720,52),Color("#151d29"),Color("#303e52")); _txt(Vector2(1000,y+34),str(vals[i]),19,WHITE)
 _button(_btn(80,940,260,70),T("back"))

func _draw_credits() -> void:
 _draw_neon_backdrop(); _panel(Rect2(420,180,1080,700),Color(0.04,0.05,0.08,0.96),Color("#39475a")); _txt(Vector2(760,280),"PC GAME EMPIRE",44,WHITE); _txt(Vector2(650,380),"Design • Gameplay • Art Direction • Engineering",22,MUTED); _txt(Vector2(720,450),"Versione beta nativa Godot",22,WHITE); _txt(Vector2(600,560),"Hardware e marchi citati appartengono ai rispettivi proprietari.",18,MUTED); _button(_btn(80,920,260,70),T("back"))

func _draw_day_summary() -> void:
 _draw_header("RIEPILOGO GIORNATA"); _panel(Rect2(300,220,1320,620),PANEL,Color("#3a485b")); _txt(Vector2(400,310),"Giorno %d completato"%day,38,WHITE); _txt(Vector2(400,390),"Lavori completati totali",21,MUTED); _txt(Vector2(950,390),str(completed_jobs),28,WHITE); _txt(Vector2(400,455),"Saldo",21,MUTED); _txt(Vector2(950,455),"€ %d"%money,30,GREEN); _txt(Vector2(400,520),"Reputazione",21,MUTED); _txt(Vector2(950,520),str(reputation),28,YELLOW); _txt(Vector2(400,585),"Livello",21,MUTED); _txt(Vector2(950,585),str(level),28,WHITE); _button(_btn(1460,900,360,80),"GIORNO SUCCESSIVO")

func _draw_result() -> void:
 _draw_dim_bg(); _panel(Rect2(430,220,1060,640),Color("#0c121a"),GREEN,4); _txt(Vector2(690,320),"LAVORO COMPLETATO",42,GREEN); _txt(Vector2(650,410),"Pagamento ricevuto",23,MUTED); _txt(Vector2(800,475),"€ %d"%money,42,WHITE); _txt(Vector2(650,555),"Reputazione: %d    Livello: %d    XP: %d"%[reputation,level,xp],24,YELLOW); _txt(Vector2(610,680),"Il cliente lascia il negozio soddisfatto.",22,WHITE); _button(_btn(760,740,400,72),"CONTINUA")
 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): pass

func _draw_header(title:String) -> void:
 _panel(Rect2(25,22,1870,92),Color(0.03,0.04,0.06,0.98),Color("#29364a")); _txt(Vector2(55,78),"PC GAME EMPIRE",25,WHITE); _txt(Vector2(700,78),title,30,RED); _txt(Vector2(1640,78),"€ %d"%money,24,GREEN)
func _draw_dim_bg() -> void:
 _draw_neon_backdrop(); draw_rect(Rect2(0,0,VW,VH),Color(0,0,0,0.55))
