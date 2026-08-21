extends Node2D

const W := 1280.0
const H := 720.0
const BG := Color("#08090c")
const PANEL := Color("#111318")
const RED := Color("#e31f2b")
const RED2 := Color("#ff3546")
const WHITE := Color("#f4f5f7")
const MUTED := Color("#9ba2ad")

var selected := 0
var page := "menu"
var menu := ["NUOVA PARTITA", "CONTINUA", "IMPOSTAZIONI", "ESCI"]
var intro_step := 0
var intro_lines := [
    "Hai investito i tuoi ultimi €2.000 in un piccolo negozio PC.",
    "Il locale è pronto. Nessun dipendente. Nessun cliente fisso.",
    "Solo tu, un banco da lavoro e abbastanza soldi per non fallire subito.",
    "Oggi alzi la serranda per la prima volta."
]

func _ready() -> void:
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if page == "menu":
            if event.keycode == KEY_UP:
                selected = max(0, selected - 1)
            elif event.keycode == KEY_DOWN:
                selected = min(menu.size() - 1, selected + 1)
            elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
                _activate()
        elif page == "intro":
            if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E:
                intro_step += 1
                if intro_step >= intro_lines.size():
                    _start_game()
            elif event.keycode == KEY_ESCAPE:
                page = "menu"
    queue_redraw()

func _activate() -> void:
    match selected:
        0:
            intro_step = 0
            page = "intro"
        1:
            _start_game()
        2:
            page = "settings"
        3:
            get_tree().quit()

func _start_game() -> void:
    get_tree().change_scene_to_file("res://main.tscn")

func _draw() -> void:
    draw_rect(Rect2(0,0,W,H), BG)
    _draw_background()
    if page == "menu":
        _draw_menu()
    elif page == "intro":
        _draw_intro()
    else:
        _draw_settings()

func _draw_background() -> void:
    for i in range(15):
        var x := float(i) * 100.0
        draw_line(Vector2(x,0), Vector2(x+280,H), Color(0.14,0.02,0.03,0.25), 1)
    draw_rect(Rect2(0,0,W,6), RED)
    draw_circle(Vector2(1040,160), 230, Color(0.55,0.02,0.04,0.13))
    draw_circle(Vector2(1110,110), 130, Color(0.95,0.02,0.05,0.08))
    draw_line(Vector2(750,120),Vector2(1220,120),RED,5)
    draw_line(Vector2(850,145),Vector2(1180,145),Color("#4b1015"),2)

func _draw_menu() -> void:
    _text(Vector2(70,115), "PC SHOP", 54, WHITE)
    _text(Vector2(70,170), "EMPIRE", 64, RED2)
    _text(Vector2(73,205), "BUILD · REPAIR · SELL · EXPAND", 15, MUTED)
    _box(Rect2(68,250,410,365), Color(0.04,0.045,0.055,0.96), Color("#292d35"), 2)
    var y := 315
    for i in range(menu.size()):
        var active := i == selected
        if active:
            draw_rect(Rect2(92,y-33,330,50), Color("#331015"))
            draw_line(Vector2(92,y-33),Vector2(92,y+17),RED2,5)
        _text(Vector2(120,y), menu[i], 22, WHITE if active else MUTED)
        y += 70
    _text(Vector2(92,585), "↑ ↓ SCEGLI   ·   INVIO CONFERMA", 12, MUTED)

    _box(Rect2(700,220,500,350), Color("#101217"), Color("#30353e"), 2)
    _text(Vector2(740,265), "GIORNO ZERO", 16, RED2)
    _text(Vector2(740,308), "CAPITALE INIZIALE", 12, MUTED)
    _text(Vector2(740,350), "€ 2.000", 38, Color("#73e89a"))
    _text(Vector2(740,405), "SEDE", 12, MUTED)
    _text(Vector2(740,442), "PICCOLO PC SHOP", 23, WHITE)
    _text(Vector2(740,493), "OBIETTIVO", 12, MUTED)
    _text(Vector2(740,528), "COSTRUISCI IL TUO IMPERO", 20, WHITE)

func _draw_intro() -> void:
    _box(Rect2(100,110,1080,500), Color(0.03,0.035,0.045,0.97), Color("#30353e"), 2)
    _text(Vector2(140,165), "PROLOGO", 16, RED2)
    _text(Vector2(140,225), "PC SHOP EMPIRE", 42, WHITE)
    _text(Vector2(140,310), intro_lines[min(intro_step, intro_lines.size()-1)], 22, WHITE)
    _text(Vector2(140,360), "La città non sa ancora chi sei.", 16, MUTED)
    _text(Vector2(140,390), "Tra poco entrerà il tuo primo cliente.", 16, MUTED)
    var dots := ""
    for i in range(intro_lines.size()):
        dots += "● " if i <= intro_step else "○ "
    _text(Vector2(140,485), dots, 18, RED2)
    _text(Vector2(140,560), "INVIO / SPAZIO / E  →  CONTINUA", 13, MUTED)

func _draw_settings() -> void:
    _box(Rect2(250,145,780,430), Color(0.04,0.045,0.055,0.97), Color("#30353e"), 2)
    _text(Vector2(305,205), "IMPOSTAZIONI", 34, WHITE)
    _text(Vector2(305,270), "Schermo: Finestra 1280×720", 18, MUTED)
    _text(Vector2(305,320), "Comandi: WASD / Frecce", 18, MUTED)
    _text(Vector2(305,370), "Interazione: E", 18, MUTED)
    _text(Vector2(305,420), "Assemblaggio: ↑ ↓ + E", 18, MUTED)
    _text(Vector2(305,500), "ESC per tornare al menu (prossima build)", 14, MUTED)

func _font():
    return ThemeDB.fallback_font

func _text(pos:Vector2, text:String, size:=18, color:=WHITE) -> void:
    draw_string(_font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _box(rect:Rect2, color:Color, border:=Color("#343943"), width:=2.0) -> void:
    draw_rect(rect,color,true)
    draw_rect(rect,border,false,width)
