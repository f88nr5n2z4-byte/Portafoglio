extends "res://maximum_quality_pass.gd"

func _setup_audio() -> void:
	pass

func _fill_music() -> void:
	pass

func _beep(_freq:=520.0, _duration:=0.055, _kind:="ui") -> void:
	pass

func _apply_video_settings() -> void:
	Engine.max_fps = int(settings.fps)

func _apply_quality() -> void:
	pass
