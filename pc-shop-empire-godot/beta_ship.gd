extends "res://beta_commercial.gd"

func _settings_click(p:Vector2) -> void:
	var rows=["resolution","window_mode","vsync","fps","quality","language","master","music","sfx","ui"]
	for i in range(rows.size()):
		if Rect2(760,205+i*67,720,52).has_point(p):
			var k:String=rows[i]
			var idx:=0
			match k:
				"resolution":
					idx=resolutions.find(String(settings.resolution))
					settings.resolution=resolutions[(idx+1)%resolutions.size()]
				"window_mode":
					var modes=["Windowed","Borderless","Fullscreen"]
					idx=modes.find(String(settings.window_mode))
					settings.window_mode=modes[(idx+1)%modes.size()]
				"vsync": settings.vsync=not bool(settings.vsync)
				"fps":
					var fpss=[30,60,120,144,240,0]
					idx=fpss.find(int(settings.fps))
					settings.fps=fpss[(idx+1)%fpss.size()]
				"quality":
					idx=quality_levels.find(String(settings.quality))
					settings.quality=quality_levels[(idx+1)%quality_levels.size()]
				"language":
					language="en" if language=="it" else "it"
					settings.language=language
				_:
					settings[k]=fmod(float(settings[k])+0.25,1.25)
			_apply_video_settings()
			_save_settings()
			_beep(640)
			queue_redraw()
			return
	if _btn(80,940,260,70).has_point(p):
		_save_settings()
		screen=previous_screen
		queue_redraw()

func _draw_result() -> void:
	_draw_dim_bg()
	_panel(Rect2(430,220,1060,640),Color("#0c121a"),GREEN,4)
	_txt(Vector2(690,320),L("LAVORO COMPLETATO","JOB COMPLETED"),42,GREEN)
	_txt(Vector2(650,410),L("Pagamento ricevuto","Payment received"),23,MUTED)
	_txt(Vector2(800,475),"€ %d"%money,42,WHITE)
	var stats := "%s: %d    %s: %d    XP: %d"%[L("Reputazione","Reputation"),reputation,L("Livello","Level"),level,xp]
	_txt(Vector2(650,555),stats,24,YELLOW)
	_txt(Vector2(610,680),L("Il cliente lascia il negozio soddisfatto.","The customer leaves the shop satisfied."),22,WHITE)
	_button(_btn(760,740,400,72),L("CONTINUA","CONTINUE"))
