extends Node2D

const W := 1280.0
const H := 720.0
const DARK := Color("#080a0e")
const FLOOR := Color("#17191e")
const RED := Color("#e51f2e")
const RED_GLOW := Color("#ff3445")
const WHITE := Color("#f3f3f3")
const MUTED := Color("#a8adb6")
const GREEN := Color("#74e89b")

var player := Vector2(640,470)
var speed := 235.0
var walk_t := 0.0
var money := 2000
var reputation := 0
var day := 1
var level := 1
var xp := 0
var mode := "shop"
var near_zone := ""
var message := "Vai al bancone e parla con il primo cliente."
var customer_pos := Vector2(805,325)
var customer_target := Vector2(760,255)
var job_active := false
var build_complete := false
var inventory := ["CPU","Scheda Madre","RAM","GPU","SSD","PSU","Raffreddamento"]
var selected_part := 0
var build_parts := {"CPU":false,"Scheda Madre":false,"RAM":false,"GPU":false,"SSD":false,"PSU":false,"Case":true,"Raffreddamento":false}

var zones := [
 {"id":"counter","rect":Rect2(650,170,260,130)},
 {"id":"market","rect":Rect2(75,145,440,145)},
 {"id":"build","rect":Rect2(960,150,250,175)},
 {"id":"used","rect":Rect2(75,455,450,125)},
 {"id":"exit","rect":Rect2(540,635,205,60)}
]

func _ready() -> void:
 queue_redraw()

func _process(delta: float) -> void:
 if mode == "shop":
  var dir := Input.get_vector("move_left","move_right","move_up","move_down")
  if dir.length() > 0.05:
   player += dir.normalized() * speed * delta
   player.x = clamp(player.x,45.0,915.0)
   player.y = clamp(player.y,85.0,625.0)
   walk_t += delta * 11.0
  _update_near()
  if customer_pos.distance_to(customer_target) > 3.0:
   customer_pos = customer_pos.move_toward(customer_target,85.0*delta)
 queue_redraw()

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("interact"):
  if mode == "shop": _interact()
  else: _install_selected()
 elif event.is_action_pressed("cancel"):
  if mode != "shop":
   mode = "shop"
   message = "Sei tornato nel negozio."
 elif mode == "build" and event is InputEventKey and event.pressed:
  if event.keycode == KEY_UP: selected_part = max(0,selected_part-1)
  if event.keycode == KEY_DOWN: selected_part = min(inventory.size()-1,selected_part+1)

func _update_near() -> void:
 near_zone = ""
 var best := 99999.0
 for z in zones:
  var r: Rect2 = z.rect
  var p := Vector2(clamp(player.x,r.position.x,r.end.x),clamp(player.y,r.position.y,r.end.y))
  var d := player.distance_to(p)
  if d < 45.0 and d < best:
   best = d
   near_zone = z.id

func _interact() -> void:
 match near_zone:
  "counter":
   if not job_active:
    job_active = true
    message = "Marco: Ho €1.300. Voglio giocare bene a 1440p. Prepara il PC."
   elif build_complete:
    money += 1300
    reputation += 2
    xp += 180
    level = 1 + int(xp/500)
    job_active = false
    build_complete = false
    for k in build_parts.keys(): build_parts[k] = (k == "Case")
    message = "PC consegnato! +€1.300 · +2 reputazione."
   else:
    message = "Marco sta aspettando il suo PC 1440p."
  "market": message = "Market: componenti ordinati. Ora vai al laboratorio."
  "build":
   if job_active:
    mode = "build"
    message = "ASSEMBLAGGIO · ↑↓ scegli · E installa · ESC esci"
   else: message = "Prima accetta un ordine cliente."
  "used": message = "USATO: qui comprerai PC e GPU con possibili guasti nascosti."
  "exit":
   day += 1
   message = "Giorno %d. Il mercato GPU è cambiato." % day
  _: message = "Avvicinati a una postazione e premi E."

func _install_selected() -> void:
 if inventory.is_empty(): return
 var p: String = inventory[selected_part]
 build_parts[p] = true
 var done := true
 for k in build_parts.keys():
  if not build_parts[k]: done = false
 if done:
  build_complete = true
  message = "BUILD COMPLETA! ESC e torna dal cliente."
 else:
  message = "%s installato." % p

func _font(): return ThemeDB.fallback_font
func _text(p:Vector2,t:String,s:=18,c:=WHITE): draw_string(_font(),p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,s,c)
func _box(r:Rect2,c:Color,b:=Color("#343943"),w:=2.0):
 draw_rect(r,c,true)
 draw_rect(r,b,false,w)

func _draw() -> void:
 if mode == "build": _draw_build()
 else: _draw_shop()

func _draw_shop() -> void:
 draw_rect(Rect2(0,0,W,H),DARK)
 draw_rect(Rect2(45,55,870,575),FLOOR)
 draw_rect(Rect2(925,55,310,575),Color("#101217"))
 for x in range(55,910,52): draw_line(Vector2(x,55),Vector2(x,630),Color("#242831"),1)
 for y in range(55,635,52): draw_line(Vector2(45,y),Vector2(915,y),Color("#242831"),1)
 for x in range(935,1235,48): draw_line(Vector2(x,55),Vector2(x,630),Color("#20242c"),1)
 for y in range(55,635,48): draw_line(Vector2(925,y),Vector2(1235,y),Color("#20242c"),1)

 _box(Rect2(345,72,290,70),Color("#0d0f13"),Color("#2f333a"),2)
 _text(Vector2(390,106),"PC SHOP",26,WHITE)
 _text(Vector2(390,134),"EMPIRE",29,RED_GLOW)
 draw_line(Vector2(335,147),Vector2(645,147),RED,5)
 draw_line(Vector2(75,95),Vector2(290,95),RED,4)
 draw_line(Vector2(665,95),Vector2(890,95),RED,4)

 _box(Rect2(75,150,440,110),Color("#0d1015"))
 _text(Vector2(92,175),"GAMING ZONE / MARKET",15,RED_GLOW)
 for i in range(5):
  var bx := 92+i*80
  _box(Rect2(bx,188,60,52),Color("#111722"),Color("#353a43"))
  draw_circle(Vector2(bx+30,214),11,Color("#8b37ff"))
  draw_circle(Vector2(bx+30,214),6,Color("#25d5ff"))

 _box(Rect2(225,315,330,90),Color("#241b17"),Color("#4b3328"))
 for i in range(4):
  _box(Rect2(245+i*76,330,55,58),Color("#141820"))
  draw_circle(Vector2(272+i*76,356),13,Color("#b335ff"))
 _text(Vector2(245,425),"PC COMPLETI",14,MUTED)

 _box(Rect2(620,185,280,105),Color("#251a17"),Color("#563729"))
 draw_line(Vector2(625,286),Vector2(895,286),RED,5)
 _text(Vector2(682,208),"BANCO CLIENTI",14,MUTED)
 _box(Rect2(775,212,72,42),Color("#0b0d10"))
 _text(Vector2(792,240),"POS",15,Color("#76d8ff"))

 _text(Vector2(1008,82),"LABORATORIO",20,RED_GLOW)
 draw_line(Vector2(985,93),Vector2(1188,93),RED,4)
 _box(Rect2(962,120,235,185),Color("#171316"),Color("#4e3032"))
 _text(Vector2(984,145),"BANCO BUILD",14,WHITE)
 for i in range(7): draw_line(Vector2(985+i*28,160),Vector2(985+i*28,190),Color("#c6c8cf"),3)
 _box(Rect2(1000,205,155,76),Color("#231a18"),Color("#593b30"))
 _box(Rect2(1022,216,68,42),Color("#070a0e"),Color("#343b47"))
 draw_rect(Rect2(1029,223,54,28),Color("#122944"))
 for yy in range(330,575,58):
  _box(Rect2(965,yy,235,46),Color("#0e1117"),Color("#313640"))
  for xx in range(978,1176,45): _box(Rect2(xx,yy+8,32,29),Color("#191d25"),Color("#3a414d"))

 _text(Vector2(86,448),"USATO / RIPARAZIONI",14,MUTED)
 _box(Rect2(75,465,450,120),Color("#11141a"),Color("#323742"))
 for i in range(5):
  _box(Rect2(92+i*82,487,62,72),Color("#141820"))
  draw_circle(Vector2(123+i*82,522),16,Color("#303641"))
  draw_circle(Vector2(123+i*82,522),9,Color("#5d6572"))

 _draw_person(Vector2(755,245),Color("#17191d"),Color("#e3a476"),false)
 _draw_person(customer_pos,Color("#3c6a44"),Color("#d8a27d"),false)
 _draw_person(player,Color("#101114"),Color("#d6a179"),true)

 _box(Rect2(20,18,1240,42),Color(0.03,0.035,0.045,0.95),Color("#272b33"))
 _text(Vector2(35,47),"PC SHOP EMPIRE",19,WHITE)
 _text(Vector2(850,47),"REPUTAZIONE ★ %d"%reputation,15,Color("#ffca45"))
 _text(Vector2(1045,47),"LIV. %d"%level,15,WHITE)
 _text(Vector2(1150,47),"€ %d"%money,17,Color("#7dff9c"))

 _box(Rect2(18,82,255,122),Color(0.04,0.045,0.06,0.93),Color("#3a3e46"))
 _text(Vector2(32,108),"MODALITÀ: NEGOZIO",14,WHITE)
 _text(Vector2(32,134),"OBIETTIVO",12,MUTED)
 var objective := "Accetta il cliente" if not job_active else ("Consegna il PC" if build_complete else "Assembla il PC")
 _text(Vector2(32,158),objective,16,RED_GLOW)
 _text(Vector2(32,185),"WASD muovi · E interagisci",12,MUTED)

 _box(Rect2(325,660,630,42),Color(0.04,0.045,0.055,0.95),Color("#3a3e46"))
 _text(Vector2(342,687),message,13,WHITE)
 if near_zone != "":
  _box(Rect2(540,590,200,42),Color("#101417"),RED_GLOW)
  _text(Vector2(585,617),"E  INTERAGISCI",14,WHITE)

func _draw_person(pos:Vector2,shirt:Color,skin:Color,is_player:bool) -> void:
 var bob := sin(walk_t)*2.0 if is_player else 0.0
 var p := pos+Vector2(0,bob)
 draw_set_transform(p+Vector2(0,18),0,Vector2(1,0.45))
 draw_circle(Vector2.ZERO,16,Color(0,0,0,0.38))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 draw_rect(Rect2(p.x-10,p.y+2,8,17),Color("#1c222d"))
 draw_rect(Rect2(p.x+2,p.y+2,8,17),Color("#1c222d"))
 draw_rect(Rect2(p.x-14,p.y-21,28,28),shirt)
 draw_circle(p+Vector2(0,-30),10,skin)
 draw_arc(p+Vector2(0,-34),10,PI,TAU,14,Color("#201815"),6)
 draw_circle(p+Vector2(-4,-29),1.5,Color("#101114"))
 draw_circle(p+Vector2(4,-29),1.5,Color("#101114"))
 if is_player: draw_line(p+Vector2(-8,-8),p+Vector2(8,-8),RED,3)

func _draw_build() -> void:
 draw_rect(Rect2(0,0,W,H),Color("#09090b"))
 draw_rect(Rect2(0,0,W,H),Color("#121114"))
 for x in range(0,1280,80): draw_line(Vector2(x,0),Vector2(x,720),Color("#1d1b1f"),1)
 draw_line(Vector2(0,90),Vector2(1280,90),RED,5)
 _text(Vector2(42,55),"MODALITÀ: ASSEMBLAGGIO",18,WHITE)
 _text(Vector2(42,82),"Installa tutti i componenti richiesti",13,MUTED)
 draw_rect(Rect2(0,570,1280,150),Color("#291b17"))
 draw_line(Vector2(0,570),Vector2(1280,570),Color("#5e3e30"),4)

 _box(Rect2(330,100,600,475),Color("#101216"),Color("#555c67"),4)
 _box(Rect2(365,135,530,385),Color("#080a0d"),Color("#2b3038"),2)
 _box(Rect2(430,180,300,230),Color("#15191f"),Color("#384451"),3)
 draw_circle(Vector2(535,250),54,Color("#202630"))
 draw_circle(Vector2(535,250),34,Color("#0d1117"))
 draw_circle(Vector2(535,250),18,RED if build_parts["CPU"] else Color("#343942"))
 for i in range(4): draw_rect(Rect2(620+i*18,205,9,120),RED if build_parts["RAM"] else Color("#252a31"))
 _box(Rect2(430,365,370,66),Color("#161a20"),Color("#414854"),2)
 draw_circle(Vector2(500,398),22,Color("#242b35"))
 draw_circle(Vector2(555,398),22,Color("#242b35"))
 _text(Vector2(630,403),"GEFORCE RTX" if build_parts["GPU"] else "GPU SLOT",13,MUTED)
 _box(Rect2(690,445,165,60),Color("#15191f"),Color("#343a44"))
 _text(Vector2(722,482),"PSU",16,MUTED)
 for i in range(3):
  draw_circle(Vector2(835,190+i*95),34,Color("#191e25"))
  draw_arc(Vector2(835,190+i*95),26,0,TAU,32,RED_GLOW if build_parts["Raffreddamento"] else Color("#31363f"),5)

 _box(Rect2(18,105,255,250),Color(0.035,0.04,0.05,0.97),Color("#383d46"))
 _text(Vector2(35,135),"OBIETTIVO",14,WHITE)
 _text(Vector2(35,162),"Assembla il PC",16,RED_GLOW)
 var yy := 195
 for k in build_parts.keys():
  var mark := "✓" if build_parts[k] else "□"
  _text(Vector2(36,yy),"%s  %s"%[mark,k],13,GREEN if build_parts[k] else MUTED)
  yy += 23

 _box(Rect2(980,85,280,520),Color(0.035,0.04,0.05,0.98),Color("#383d46"))
 _text(Vector2(1000,118),"COMPONENTI DISPONIBILI",14,WHITE)
 var ry := 155
 for i in range(inventory.size()):
  var active := i == selected_part
  if active:
   draw_rect(Rect2(994,ry-22,250,44),Color("#321115"))
   draw_line(Vector2(994,ry-22),Vector2(994,ry+22),RED_GLOW,4)
  var part:String = inventory[i]
  _text(Vector2(1015,ry),part,14,WHITE if active else MUTED)
  _text(Vector2(1195,ry),"x1",12,WHITE)
  ry += 54
 _box(Rect2(980,620,280,62),Color("#0c0e12"),Color("#3b4049"))
 _text(Vector2(1000,646),"↑ ↓ SCEGLI · E INSTALLA",13,WHITE)
 _text(Vector2(1000,670),"ESC TORNA AL NEGOZIO",12,MUTED)
 _box(Rect2(325,620,600,52),Color("#0c0e12"),Color("#3b4049"))
 _text(Vector2(346,653),message,13,WHITE)
