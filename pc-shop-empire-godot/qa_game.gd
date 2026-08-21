extends "res://beta_runtime.gd"

func _setup_audio() -> void:
	pass

func _fill_music() -> void:
	pass

func _beep(_freq:=520.0, _duration:=0.055, _kind:="ui") -> void:
	pass

func _apply_video_settings() -> void:
	# Video modes are exercised by the real build; avoid changing the CI headless display.
	Engine.max_fps = int(settings.fps)
