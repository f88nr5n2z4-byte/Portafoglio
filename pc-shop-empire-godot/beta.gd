extends Node2D

# PC SHOP EMPIRE — BETA CORE
# Native Godot 4.7, 1920x1080. Complete Day-1 vertical slice.

const W := 1920.0
const H := 1080.0
const RED := Color("#ef233c")
const RED2 := Color("#ff3850")
const BG := Color("#07090d")
const PANEL := Color("#0e131b")
const PANEL2 := Color("#151b25")
const LINE := Color("#303947")
const WHITE := Color("#f4f7fb")
const MUTED := Color("#9ba8b8")
const GREEN := Color("#43e17b")
const GOLD := Color("#ffca3a")
const BLUE := Color("#4cc9f0")

var screen := "menu"
var menu_index := 0
var money := 2000
var reputation := 0
var xp := 0
var level := 1
var day := 1
var time_minutes := 510
var player := Vector2(920, 735)
var player_speed := 360.0
var walk_t := 0.0
var near_zone := ""
var customer_pos := Vector2(1710, 860)
var customer_target := Vector2(1265, 395)
var customer_arrived := false
var order_state := "waiting" # waiting, accepted, shopping, parts_ready, building, benchmark, ready, delivered
var selected_catalog := 0
var selected_build := 0
var basket_total := 0
var status_text := "Il tuo primo giorno sta per iniziare."
var fade := 1.0
var save_exists := false

var parts := [
 {"type":"CPU","name":"AMD Ryzen 5 9600X","price":185,"spec":"6C/12T · AM5"},
 {"type":"Scheda Madre","name":"Gigabyte B850 Gaming WiFi6","price":166,"spec":"AM5 · DDR5"},
 {"type":"RAM","name":"Kingston Fury Beast 32GB DDR5-6000","price":172,"spec":"32 GB · DDR5"},
 {"type":"GPU","name":"Palit GeForce RTX 5070 12GB","price":540,"spec":"12 GB GDDR7"},
 {"type":"SSD","name":"Crucial P310 2TB NVMe","price":225,"spec":"2 TB · PCIe NVMe"},
 {"type":"PSU","name":"Seasonic Core GX 850W","price":109,"spec":"850W · 80+ Gold"},
 {"type":"Case","name":"NZXT H7 Flow","price":114,"spec":"ATX Mid Tower"},
 {"type":"Raffreddamento","name":"Noctua NH-D15","price":114,"spec":"Dual tower air"}
]
var owned := {}
var installed := {}

var zones := [
 {"id":"counter","rect":Rect2(1110,260,380,220)},
 {"id":"market","rect":Rect2(120,230,540,270)},
 {"id":"warehouse","rect":Rect2(1450,560,350,270)},
 {"id":"lab","rect":Rect2(1510,130,300,330)},
 {"id":"exit","rect":Rect2(785,940,350,100)}
]

func _ready() -> void:
 save_exists = FileAccess.file_exists("user://pc_shop_empire_beta.save")
 for p in parts:
  owned[p.type] = false
  installed[p.type] = false
 queue_redraw()

func _process(delta: float) -> void:
 fade = move_toward(fade, 0.0, delta * 1.8)
 if screen == "shop":
  var d := Input.get_vector("move_left","move_right","move_up","move_down")
  if d.length() > 0.05:
   player += d.normalized() * player_speed * delta
   player.x = clamp(player.x, 85.0, 1815.0)
   player.y = clamp(player.y, 135.0, 930.0)
   walk_t += delta * 12.0
   time_minutes += int(delta * 2.5)
  _update_near()
  _update_customer(delta)
 queue_redraw()

func _input(e: InputEvent) -> void:
 if not e.is_pressed(): return
 if screen == "menu":
  if e.is_action_pressed("move_up"): menu_index = max(0, menu_index - 1)
  elif e.is_action_pressed("move_down"): menu_index = min(3, menu_index + 1)
  elif e.is_action_pressed("interact"):
   if menu_index == 0: _new_game()
   elif menu_index == 1 and save_exists: _load_game()
   elif menu_index == 2: screen = "settings"
   elif menu_index == 3: get_tree().quit()
 elif screen == "intro":
  if e.is_action_pressed("interact"): screen = "shop"; fade = 1.0
 elif screen == "shop":
  if e.is_action_pressed("interact"): _interact_shop()
  elif e.is_action_pressed("cancel"): screen = "pause"
 elif screen == "dialog":
  if e.is_action_pressed("interact"):
   order_state = "accepted"
   status_text = "Ordine #001 accettato. Vai al terminale componenti."
   screen = "shop"
   _save_game()
  elif e.is_action_pressed("cancel"):
   screen = "shop"
 elif screen == "catalog":
  if e.is_action_pressed("move_up"): selected_catalog = max(0, selected_catalog - 1)
  elif e.is_action_pressed("move_down"): selected_catalog = min(parts.size()-1, selected_catalog + 1)
  elif e.is_action_pressed("interact"): _buy_selected()
  elif e.is_action_pressed("cancel"): screen = "shop"
 elif screen == "warehouse":
  if e.is_action_pressed("interact"):
   order_state = "parts_ready"
   status_text = "Scatole ritirate. Vai nel laboratorio."
   screen = "shop"
   _save_game()
  elif e.is_action_pressed("cancel"): screen = "shop"
 elif screen == "build":
  if e.is_action_pressed("move_up"): selected_build = max(0, selected_build - 1)
  elif e.is_action_pressed("move_down"): selected_build = min(parts.size()-1, selected_build + 1)
  elif e.is_action_pressed("interact"): _install_selected()
  elif e.is_action_pressed("cancel"): screen = "shop"
 elif screen == "benchmark":
  if e.is_action_pressed("interact"):
   order_state = "ready"
   screen = "shop"
   status_text = "Benchmark superato. Consegna il PC a Marco."
   _save_game()
 elif screen == "end_day":
  if e.is_action_pressed("interact"):
   day += 1; time_minutes = 510; screen = "shop"; _save_game()
 elif screen == "pause" or screen == "settings":
  if e.is_action_pressed("cancel") or e.is_action_pressed("interact"): screen = "shop" if order_state != "waiting" else "menu"
 queue_redraw()

func _new_game() -> void:
 money = 2000; reputation = 0; xp = 0; level = 1; day = 1; time_minutes = 510
 player = Vector2(920,735); customer_pos = Vector2(1710,860); customer_arrived = false
 order_state = "waiting"; basket_total = 0
 for p in parts: owned[p.type] = false; installed[p.type] = false
 screen = "intro"; fade = 1.0
 status_text = "Apri il negozio e parla con il tuo primo cliente."
 _save_game()

func _update_customer(delta: float) -> void:
 if customer_pos.distance_to(customer_target) > 4.0:
  customer_pos = customer_pos.move_toward(customer_target, 155.0 * delta)
 else:
  customer_arrived = true

func _update_near() -> void:
 near_zone = ""
 var best := 999999.0
 for z in zones:
  var r: Rect2 = z.rect
  var p := Vector2(clamp(player.x,r.position.x,r.end.x),clamp(player.y,r.position.y,r.end.y))
  var d := player.distance_to(p)
  if d < 80.0 and d < best: best = d; near_zone = z.id

func _interact_shop() -> void:
 match near_zone:
  "counter":
   if order_state == "waiting" and customer_arrived: screen = "dialog"
   elif order_state == "ready":
    order_state = "delivered"; money += 1300; reputation += 75; xp += 180; level = 1 + int(xp / 500)
    status_text = "Ordine consegnato! +€1.300 · +75 REP · +180 XP"
    _save_game()
   elif order_state == "delivered": screen = "end_day"
   else: status_text = "Marco sta aspettando il completamento dell'ordine."
  "market":
   if order_state == "accepted" or order_state == "shopping": screen = "catalog"; order_state = "shopping"
   else: status_text = "Non hai ordini da acquistare."
  "warehouse":
   if _all_owned() and order_state == "shopping": screen = "warehouse"
   else: status_text = "Il magazzino non ha ancora un pacco pronto."
  "lab":
   if order_state == "parts_ready" or order_state == "building": screen = "build"; order_state = "building"
   elif order_state == "benchmark": screen = "benchmark"
   else: status_text = "Ti servono prima tutti i componenti."
  "exit": screen = "pause"
  _: status_text = "Avvicinati a una postazione e premi E."

func _buy_selected() -> void:
 var p: Dictionary = parts[selected_catalog]
 if owned[p.type]:
  status_text = "%s è già nel carrello." % p.name
  return
 if money < p.price:
  status_text = "Fondi insufficienti."
  return
 money -= p.price; basket_total += p.price; owned[p.type] = true
 status_text = "Acquistato: %s · €%d" % [p.name,p.price]
 if _all_owned(): status_text = "Ordine componenti completo. Vai al magazzino a ritirare le scatole."
 _save_game()

func _install_selected() -> void:
 var p: Dictionary = parts[selected_build]
 if not owned[p.type]: status_text = "Questo componente non è disponibile."; return
 if installed[p.type]: status_text = "%s è già installato." % p.type; return
 # Accessible compatibility checks used by beta build.
 if p.type == "GPU" and not installed["PSU"]:
  status_text = "Installa prima l'alimentatore per preparare i cavi GPU."; return
 if p.type == "CPU" and not installed["Scheda Madre"]:
  status_text = "Installa prima la scheda madre."; return
 if p.type == "RAM" and not installed["Scheda Madre"]:
  status_text = "Installa prima la scheda madre."; return
 installed[p.type] = true
 status_text = "%s installato correttamente." % p.type
 if _all_installed():
  order_state = "benchmark"
  status_text = "Assemblaggio completato. Premi ESC e usa di nuovo il banco per il benchmark."
 _save_game()

func _all_owned() -> bool:
 for p in parts:
  if not owned[p.type]: return false
 return true

func _all_installed() -> bool:
 for p in parts:
  if not installed[p.type]: return false
 return true

func _save_game() -> void:
 var f := FileAccess.open("user://pc_shop_empire_beta.save",FileAccess.WRITE)
 if f == null: return
 var data := {"money":money,"rep":reputation,"xp":xp,"level":level,"day":day,"time":time_minutes,"player":[player.x,player.y],"order":order_state,"basket":basket_total,"owned":owned,"installed":installed}
 f.store_string(JSON.stringify(data)); save_exists = true

func _load_game() -> void:
 var f := FileAccess.open("user://pc_shop_empire_beta.save",FileAccess.READ)
 if f == null: return
 var d = JSON.parse_string(f.get_as_text())
 if typeof(d) != TYPE_DICTIONARY: return
 money=int(d.get("money",2000)); reputation=int(d.get("rep",0)); xp=int(d.get("xp",0)); level=int(d.get("level",1)); day=int(d.get("day",1)); time_minutes=int(d.get("time",510)); order_state=str(d.get("order","waiting")); basket_total=int(d.get("basket",0))
 var pp=d.get("player",[920,735]); player=Vector2(float(pp[0]),float(pp[1])); owned=d.get("owned",owned); installed=d.get("installed",installed)
 customer_pos=customer_target; customer_arrived=true; screen="shop"; fade=1.0; status_text="Partita caricata."

func _draw() -> void:
 match screen:
  "menu": _draw_menu()
  "intro": _draw_intro()
  "shop": _draw_shop()
  "dialog": _draw_shop(); _draw_dialog()
  "catalog": _draw_catalog()
  "warehouse": _draw_warehouse()
  "build": _draw_build()
  "benchmark": _draw_benchmark()
  "end_day": _draw_end_day()
  "pause": _draw_shop(); _draw_pause()
  "settings": _draw_settings()
 if fade > 0.01: draw_rect(Rect2(0,0,W,H),Color(0,0,0,fade))

func _font(): return ThemeDB.fallback_font
func _txt(p:Vector2,t:String,s:=24,c:=WHITE): draw_string(_font(),p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,s,c)
func _center(y:float,t:String,s:=32,c:=WHITE): draw_string(_font(),Vector2(0,y),t,HORIZONTAL_ALIGNMENT_CENTER,W,s,c)
func _box(r:Rect2,c:=PANEL,b:=LINE,w:=2.0): draw_rect(r,c,true); draw_rect(r,b,false,w)
func _button(r:Rect2,t:String,active:=false): _box(r,Color("#271016") if active else PANEL2,RED2 if active else LINE,3 if active else 2); _txt(r.position+Vector2(28,r.size.y*0.63),t,26,WHITE)

func _draw_menu() -> void:
 draw_rect(Rect2(0,0,W,H),BG)
 # premium PC-shop background
 for i in range(14):
  var x=1050+i*60; draw_line(Vector2(x,110),Vector2(x-300,970),Color(0.12,0.16,0.23,0.25),2)
 for i in range(6):
  var r=Rect2(1110+i*118,260+(i%2)*130,95,220); _box(r,Color("#0b1017"),Color("#293443")); draw_circle(r.position+Vector2(48,60),31,Color("#8a2be2")); draw_circle(r.position+Vector2(48,60),22,Color("#1ebcff")); draw_line(r.position+Vector2(12,165),r.position+Vector2(83,165),RED,5)
 draw_line(Vector2(0,90),Vector2(W,90),RED,5)
 _txt(Vector2(120,185),"PC SHOP",64,WHITE); _txt(Vector2(120,255),"EMPIRE",74,RED2); _txt(Vector2(125,305),"BUILD · FIX · UPGRADE · EMPIRE",20,MUTED)
 var opts=["NUOVA PARTITA","CONTINUA" if save_exists else "CONTINUA  [nessun salvataggio]","IMPOSTAZIONI","ESCI"]
 for i in range(4): _button(Rect2(120,410+i*98,520,72),opts[i],menu_index==i)
 _txt(Vector2(120,930),"BETA 0.2 · NATIVE GODOT · 1920×1080",18,MUTED)
 _txt(Vector2(1110,865),"IL TUO NEGOZIO. LE TUE BUILD. IL TUO IMPERO.",21,WHITE)

func _draw_intro() -> void:
 draw_rect(Rect2(0,0,W,H),Color("#080a0e")); draw_line(Vector2(0,100),Vector2(W,100),RED,5)
 _center(280,"GIORNO 1",54,RED2); _center(360,"Ogni impero comincia da un solo PC.",34,WHITE)
 _center(455,"Hai investito i tuoi ultimi €2.000 in un piccolo negozio di informatica.",25,MUTED)
 _center(505,"La serranda si alza. Il primo cliente sta arrivando.",25,MUTED)
 _box(Rect2(610,650,700,95),Color("#11151d"),RED,2); _center(710,"E  ·  APRI IL NEGOZIO",27,WHITE)

func _draw_shop() -> void:
 draw_rect(Rect2(0,0,W,H),Color("#090c11")); draw_rect(Rect2(55,105,1360,825),Color("#171c23")); draw_rect(Rect2(1435,105,430,825),Color("#11151b"))
 # floor tiles
 for x in range(65,1410,64): draw_line(Vector2(x,105),Vector2(x,930),Color("#252c36"),1)
 for y in range(105,935,64): draw_line(Vector2(55,y),Vector2(1415,y),Color("#252c36"),1)
 # displays
 _box(Rect2(110,195,520,200),Color("#0d1219")); _txt(Vector2(140,230),"GAMING & COMPONENTI",22,RED2)
 for i in range(5):
  var x=145+i*92; _box(Rect2(x,255,70,105),Color("#0c1016")); draw_circle(Vector2(x+35,293),22,Color("#6124bb")); draw_arc(Vector2(x+35,293),17,0,TAU,24,BLUE,4); draw_line(Vector2(x+12,340),Vector2(x+58,340),RED,4)
 _box(Rect2(390,530,500,150),Color("#2a1c18"),Color("#57382f")); _txt(Vector2(425,560),"PC COMPLETI",19,MUTED)
 for i in range(4): _box(Rect2(430+i*105,580,72,75),Color("#111720"));
 # counter
 _box(Rect2(1080,250,365,210),Color("#251917"),Color("#5c3833")); draw_line(Vector2(1080,452),Vector2(1445,452),RED,7); _txt(Vector2(1150,290),"BANCO CLIENTI",20,WHITE); _box(Rect2(1260,320,100,60),Color("#080b0f")); _txt(Vector2(1285,360),"POS",20,BLUE)
 # warehouse and lab
 _box(Rect2(1470,520,350,300),Color("#0d1219")); _txt(Vector2(1510,555),"MAGAZZINO",23,WHITE)
 for yy in range(590,790,58):
  draw_line(Vector2(1490,yy),Vector2(1795,yy),Color("#414956"),4)
  for xx in range(1510,1770,70): _box(Rect2(xx,yy-38,52,32),Color("#5a3722"),Color("#8a5b37"))
 _box(Rect2(1490,150,330,290),Color("#161316"),Color("#573238")); _txt(Vector2(1545,187),"LABORATORIO",24,RED2); _box(Rect2(1530,230,250,120),Color("#291c18")); _box(Rect2(1580,250,130,80),Color("#080b10")); draw_rect(Rect2(1595,265,100,50),Color("#153d72"));
 for i in range(7): draw_line(Vector2(1535+i*37,385),Vector2(1535+i*37,420),Color("#aab4c0"),4)
 # entrance
 _box(Rect2(785,930,350,100),Color("#0c1118"),Color("#536070")); _txt(Vector2(870,988),"INGRESSO",23,MUTED)
 # characters
 _person(player,true); _person(customer_pos,false)
 # HUD
 _box(Rect2(18,18,1884,70),Color(0.025,0.035,0.05,0.97),Color("#2a3441")); _txt(Vector2(42,62),"PC SHOP EMPIRE",27,WHITE); _txt(Vector2(860,60),"€ %d"%money,28,GREEN); _txt(Vector2(1080,60),"REP ★ %d"%reputation,22,GOLD); _txt(Vector2(1285,60),"LIVELLO %d"%level,22,WHITE); _txt(Vector2(1490,60),"GIORNO %d"%day,22,WHITE); _txt(Vector2(1665,60),_clock_text(),22,MUTED)
 _box(Rect2(20,850,620,70),Color(0.03,0.04,0.055,0.96),Color("#374252")); _txt(Vector2(42,880),"OBIETTIVO",15,MUTED); _txt(Vector2(42,908),_objective(),20,RED2)
 _box(Rect2(650,970,620,68),Color(0.025,0.035,0.05,0.97),Color("#374252")); _txt(Vector2(680,1011),status_text,18,WHITE)
 if near_zone!="": _box(Rect2(780,855,300,64),Color("#10151c"),RED,3); _txt(Vector2(835,897),"E  INTERAGISCI",22,WHITE)

func _person(pos:Vector2,is_player:bool) -> void:
 var bob=sin(walk_t)*4.0 if is_player else 0.0; var p=pos+Vector2(0,bob)
 draw_set_transform(p+Vector2(0,35),0,Vector2(1,0.42)); draw_circle(Vector2.ZERO,28,Color(0,0,0,0.38)); draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var shirt=Color("#101216") if is_player else Color("#315d35"); var skin=Color("#d9a27c")
 draw_rect(Rect2(p.x-16,p.y+8,12,30),Color("#202735")); draw_rect(Rect2(p.x+4,p.y+8,12,30),Color("#202735")); draw_rect(Rect2(p.x-23,p.y-37,46,50),shirt); draw_circle(p+Vector2(0,-55),18,skin); draw_arc(p+Vector2(0,-62),19,PI,TAU,24,Color("#211815"),9); draw_circle(p+Vector2(-7,-54),2,Color("#0b0d10")); draw_circle(p+Vector2(7,-54),2,Color("#0b0d10"));
 if is_player: draw_line(p+Vector2(-15,-14),p+Vector2(15,-14),RED,5)
 else:
  draw_circle(p+Vector2(0,-86),15,Color("#ffffff")); draw_circle(p+Vector2(-5,-86),2,Color("#111111")); draw_circle(p+Vector2(1,-86),2,Color("#111111")); draw_circle(p+Vector2(7,-86),2,Color("#111111"))

func _draw_dialog() -> void:
 draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.58)); _box(Rect2(180,180,1560,720),Color("#0c1118"),Color("#3b4656"),3)
 _txt(Vector2(250,250),"MARCO",38,GOLD); _txt(Vector2(250,295),"Cliente · primo ordine",19,MUTED)
 # portrait
 _box(Rect2(250,350,340,390),Color("#111822")); draw_circle(Vector2(420,480),78,Color("#d9a27c")); draw_arc(Vector2(420,445),82,PI,TAU,36,Color("#2a1d18"),35); draw_rect(Rect2(330,555,180,135),Color("#315d35"));
 _txt(Vector2(660,380),"“Ciao! Ho un budget massimo di €1.300.",27,WHITE); _txt(Vector2(660,425),"Vorrei giocare bene in 1440p, soprattutto",27,WHITE); _txt(Vector2(660,470),"a Fortnite e Warzone. Deve essere silenzioso.”",27,WHITE)
 _txt(Vector2(660,550),"REQUISITI",18,MUTED); _txt(Vector2(660,592),"✓ Gaming 1440p",22,GREEN); _txt(Vector2(930,592),"✓ Buon rapporto qualità/prezzo",22,GREEN); _txt(Vector2(660,632),"✓ Silenzioso",22,GREEN); _txt(Vector2(930,632),"Budget: €1.300",22,GOLD)
 _button(Rect2(660,720,440,80),"E  ACCETTA ORDINE",true); _button(Rect2(1130,720,350,80),"ESC  TORNA",false)

func _draw_catalog() -> void:
 draw_rect(Rect2(0,0,W,H),BG); _box(Rect2(25,20,1870,80),PANEL,LINE); _txt(Vector2(55,70),"NEGOZIO COMPONENTI",30,WHITE); _txt(Vector2(1420,70),"DISPONIBILE  € %d"%money,25,GREEN); _txt(Vector2(1700,70),"SPESA  € %d"%basket_total,22,GOLD)
 _box(Rect2(25,120,330,900),Color("#0b1118")); _txt(Vector2(60,165),"ORDINE #001",22,RED2); _txt(Vector2(60,205),"PC Gaming 1440p",20,WHITE); _txt(Vector2(60,245),"Budget cliente €1.300",18,MUTED); _txt(Vector2(60,300),"COMPONENTI",17,MUTED)
 var yy=350
 for p in parts:
  _txt(Vector2(70,yy),("✓ " if owned[p.type] else "□ ")+p.type,19,GREEN if owned[p.type] else WHITE); yy+=57
 _box(Rect2(380,120,1515,900),Color("#0a0f15"));
 var y=165
 for i in range(parts.size()):
  var p:Dictionary=parts[i]; var active=i==selected_catalog; var r=Rect2(420,y,1395,88); _box(r,Color("#2b1218") if active else PANEL2,RED if active else LINE,3 if active else 2)
  _txt(Vector2(455,y+35),p.type,17,RED2); _txt(Vector2(610,y+35),p.name,22,WHITE); _txt(Vector2(610,y+65),p.spec,15,MUTED); _txt(Vector2(1580,y+48),"€ %d"%p.price,23,GREEN); _txt(Vector2(1700,y+48),"ACQUISTATO" if owned[p.type] else "E COMPRA",16,GREEN if owned[p.type] else WHITE); y+=101
 _txt(Vector2(420,1000),"↑ ↓ seleziona   ·   E acquista   ·   ESC torna al negozio",18,MUTED)

func _draw_warehouse() -> void:
 draw_rect(Rect2(0,0,W,H),Color("#0a0d12")); _txt(Vector2(80,90),"MAGAZZINO · CONSEGNA COMPONENTI",34,WHITE); draw_line(Vector2(80,110),Vector2(1840,110),RED,5)
 for i in range(8):
  var row=i/4; var col=i%4; var x=180+col*420; var y=220+row*330; _box(Rect2(x,y,300,230),Color("#17130f"),Color("#765036"),4); _txt(Vector2(x+28,y+55),parts[i].type,23,GOLD); _txt(Vector2(x+28,y+95),parts[i].name,17,WHITE); draw_line(Vector2(x+30,y+160),Vector2(x+270,y+160),Color("#a26a3b"),6)
 _box(Rect2(580,900,760,90),Color("#10161e"),RED,3); _center(958,"E  ·  RACCOGLI LE SCATOLE E PORTALE IN LABORATORIO",23,WHITE)

func _draw_build() -> void:
 draw_rect(Rect2(0,0,W,H),Color("#0a0b0e")); _txt(Vector2(40,65),"MODALITÀ ASSEMBLAGGIO",28,WHITE); draw_line(Vector2(0,90),Vector2(W,90),RED,5)
 # case close-up
 _box(Rect2(475,125,900,760),Color("#11151a"),Color("#59636f"),5); _box(Rect2(535,185,770,630),Color("#07090c"),Color("#303844"),3)
 _box(Rect2(650,260,420,350),Color("#151b20"),Color("#43505e"),3); draw_circle(Vector2(790,385),85,Color("#222a33")); draw_circle(Vector2(790,385),55,Color("#0d1218")); draw_circle(Vector2(790,385),32,RED if installed["CPU"] else Color("#333b44"));
 for i in range(4): draw_rect(Rect2(930+i*25,305,12,185),RED2 if installed["RAM"] else Color("#29313b"))
 _box(Rect2(655,600,510,95),Color("#151a20"),Color("#444c58")); _txt(Vector2(825,658),"RTX 5070" if installed["GPU"] else "GPU SLOT",23,MUTED)
 _box(Rect2(1070,700,190,80),Color("#151a20")); _txt(Vector2(1120,750),"PSU",19,MUTED)
 for i in range(3): draw_arc(Vector2(1240,300+i*145),45,0,TAU,32,RED2 if installed["Raffreddamento"] else Color("#343c46"),7)
 # list
 _box(Rect2(30,130,380,755),Color("#0c1118")); _txt(Vector2(65,178),"PROGRESSO BUILD",22,WHITE); var y=235
 for i in range(parts.size()):
  var p=parts[i]; var active=i==selected_build; if active: draw_rect(Rect2(48,y-30,330,48),Color("#351219")); _txt(Vector2(65,y),("✓" if installed[p.type] else "□")+"  "+p.type,19,GREEN if installed[p.type] else (WHITE if active else MUTED)); y+=69
 # component panel
 _box(Rect2(1425,130,455,755),Color("#0c1118")); var sp:Dictionary=parts[selected_build]; _txt(Vector2(1460,180),sp.type,18,RED2); _txt(Vector2(1460,225),sp.name,22,WHITE); _txt(Vector2(1460,260),sp.spec,17,MUTED); _txt(Vector2(1460,320),"DISPONIBILE IN MAGAZZINO",16,GREEN); _button(Rect2(1460,720,370,80),"E  INSTALLA",true)
 # hands
 draw_colored_polygon(PackedVector2Array([Vector2(300,1080),Vector2(570,820),Vector2(680,865),Vector2(570,1080)]),Color("#11151c")); draw_colored_polygon(PackedVector2Array([Vector2(1620,1080),Vector2(1350,820),Vector2(1240,865),Vector2(1350,1080)]),Color("#11151c")); draw_circle(Vector2(650,850),42,Color("#d7a07d")); draw_circle(Vector2(1270,850),42,Color("#d7a07d"));
 _box(Rect2(500,930,920,90),Color("#0c1118"),LINE); _center(985,status_text,19,WHITE)

func _draw_benchmark() -> void:
 draw_rect(Rect2(0,0,W,H),BG); _txt(Vector2(80,90),"TEST & BENCHMARK · 1440p",34,WHITE); draw_line(Vector2(80,112),Vector2(1840,112),RED,5)
 _box(Rect2(100,175,680,735),Color("#0c1118")); _txt(Vector2(150,225),"PC CLIENTE #001",22,MUTED); _txt(Vector2(150,275),"Ryzen 5 9600X + RTX 5070",28,WHITE)
 _box(Rect2(850,175,940,735),Color("#0c1118")); _txt(Vector2(910,230),"RISULTATI SIMULATI",18,MUTED)
 var tests=[{"n":"Fortnite","fps":214},{"n":"Warzone","fps":148},{"n":"Cyberpunk 2077","fps":91},{"n":"Red Dead Redemption 2","fps":102},{"n":"GTA V","fps":164}]; var y=310
 for t in tests: _txt(Vector2(920,y),t.n,23,WHITE); _txt(Vector2(1520,y),"%d FPS"%t.fps,26,GREEN); draw_line(Vector2(920,y+24),Vector2(1640,y+24),Color("#252d38"),2); y+=88
 _txt(Vector2(920,790),"CPU 67°C",20,BLUE); _txt(Vector2(1130,790),"GPU 71°C",20,BLUE); _txt(Vector2(1340,790),"Rumore 28 dB",20,BLUE); _txt(Vector2(920,850),"✓ PC STABILE · TARGET 1440p SUPERATO",24,GREEN)
 _box(Rect2(650,940,620,80),Color("#10251a"),GREEN,3); _center(991,"E  ·  APPROVA E TORNA IN NEGOZIO",22,WHITE)

func _draw_end_day() -> void:
 draw_rect(Rect2(0,0,W,H),BG); _center(190,"FINE GIORNATA",48,WHITE); _center(245,"Giorno %d completato"%day,23,MUTED); _box(Rect2(450,340,1020,420),Color("#0d131b"),Color("#34404f"),3)
 _txt(Vector2(520,410),"CLIENTI SERVITI",21,MUTED); _txt(Vector2(1280,410),"1",28,WHITE); _txt(Vector2(520,475),"RICAVI",21,MUTED); _txt(Vector2(1200,475),"+ € 1.300",28,GREEN); _txt(Vector2(520,540),"COSTO COMPONENTI",21,MUTED); _txt(Vector2(1200,540),"- € %d"%basket_total,28,RED2); _txt(Vector2(520,605),"REPUTAZIONE",21,MUTED); _txt(Vector2(1200,605),"+ 75 REP",28,GOLD); _txt(Vector2(520,670),"XP",21,MUTED); _txt(Vector2(1200,670),"+ 180 XP",28,BLUE)
 _box(Rect2(610,830,700,90),Color("#291118"),RED,3); _center(888,"E  ·  CONTINUA AL GIORNO 2",24,WHITE)

func _draw_pause() -> void:
 draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.72)); _box(Rect2(620,250,680,530),Color("#0c1118"),Color("#3d4857"),3); _center(330,"PAUSA",38,WHITE); _center(410,"Salvataggio automatico attivo",20,GREEN); _center(500,"WASD · movimento",19,MUTED); _center(545,"E · interazione",19,MUTED); _center(590,"ESC · chiudi schermate",19,MUTED); _center(690,"ESC / E  ·  RIPRENDI",22,WHITE)

func _draw_settings() -> void:
 draw_rect(Rect2(0,0,W,H),BG); _center(190,"IMPOSTAZIONI",44,WHITE); _box(Rect2(450,300,1020,430),PANEL,LINE,3); _txt(Vector2(520,380),"Risoluzione",22,MUTED); _txt(Vector2(1110,380),"1920 × 1080",24,WHITE); _txt(Vector2(520,455),"Modalità display",22,MUTED); _txt(Vector2(1110,455),"Finestra / Fullscreen da sistema",22,WHITE); _txt(Vector2(520,530),"Rendering",22,MUTED); _txt(Vector2(1110,530),"Godot GL Compatibility",22,WHITE); _txt(Vector2(520,605),"Salvataggio",22,MUTED); _txt(Vector2(1110,605),"Automatico",22,GREEN); _center(820,"E / ESC  ·  INDIETRO",22,WHITE)

func _objective() -> String:
 match order_state:
  "waiting": return "Parla con Marco al banco"
  "accepted": return "Vai al terminale e compra i componenti"
  "shopping": return "Completa l'acquisto e ritira il pacco"
  "parts_ready": return "Porta i componenti al laboratorio"
  "building": return "Assembla il PC"
  "benchmark": return "Esegui benchmark dal banco laboratorio"
  "ready": return "Consegna il PC a Marco"
  "delivered": return "Chiudi il Giorno 1 al banco"
 return "Gestisci il negozio"

func _clock_text() -> String:
 var h=int(time_minutes/60)%24; var m=int(time_minutes%60); return "%02d:%02d"%[h,m]
