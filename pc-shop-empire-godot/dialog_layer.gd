extends Node2D

var elapsed := 0.0

func _ready() -> void:
	z_index = 30
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _font():
	return ThemeDB.fallback_font

func _txt(p: Vector2, text: String, size := 16, color := Color("#f4f5f7")) -> void:
	draw_string(_font(), p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _panel(r: Rect2, fill := Color(0.035,0.04,0.055,0.97), border := Color("#3b414b")) -> void:
	draw_rect(r, fill, true)
	draw_rect(r, border, false, 2)

func _draw() -> void:
	var game = get_parent()
	if not is_instance_valid(game) or game.mode != "shop":
		return
	var close_to_counter := game.player.distance_to(Vector2(755,300)) < 155.0
	if close_to_counter and not game.job_active:
		_panel(Rect2(300,440,610,165),Color(0.025,0.03,0.04,0.98),Color("#e42132"))
		_txt(Vector2(325,472),"MARCO · CLIENTE",15,Color("#ff4655"))
		_txt(Vector2(325,505),"Ciao! Ho circa €1.300 di budget.",18)
		_txt(Vector2(325,532),"Voglio giocare bene a 1440p e vorrei un PC silenzioso.",16,Color("#c8ccd4"))
		_txt(Vector2(325,558),"Se riesci, preferirei una buona scheda video.",16,Color("#c8ccd4"))
		_txt(Vector2(325,590),"E  ACCETTA ORDINE",15,Color("#74e89b"))
	elif game.job_active and not game.build_complete:
		_panel(Rect2(1010,90,235,145),Color(0.025,0.03,0.04,0.96),Color("#e42132"))
		_txt(Vector2(1028,120),"ORDINE #001",14,Color("#ff4655"))
		_txt(Vector2(1028,147),"Marco · €1.300",16)
		_txt(Vector2(1028,174),"Gaming 1440p",15,Color("#c8ccd4"))
		_txt(Vector2(1028,201),"Stato: DA ASSEMBLARE",12,Color("#ffd166"))
	elif game.build_complete:
		_panel(Rect2(1010,90,235,145),Color(0.025,0.04,0.035,0.96),Color("#74e89b"))
		_txt(Vector2(1028,120),"ORDINE #001",14,Color("#74e89b"))
		_txt(Vector2(1028,147),"PC PRONTO",18,Color("#74e89b"))
		_txt(Vector2(1028,174),"Torna da Marco",15)
		_txt(Vector2(1028,201),"Consegna: €1.300",13,Color("#c8ccd4"))
