extends "res://beta.gd"

func _mouse_down(p: Vector2) -> void:
	if screen == "intro":
		if _btn(680,650,560,86).has_point(p):
			screen = "shop_floor"
			tutorial_step = 1
			_beep(720,0.08,"ui")
			_notify("Benvenuto in PC GAME EMPIRE")
			_autosave()
			queue_redraw()
		return
	if screen == "result":
		if _btn(760,740,400,72).has_point(p):
			screen = "shop_floor"
			_offer_next_job()
			queue_redraw()
		return
	super._mouse_down(p)
