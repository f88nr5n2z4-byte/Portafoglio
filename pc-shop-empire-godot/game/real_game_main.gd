extends Node

const StoreWorld = preload("res://game/world/store_world_3d_runtime.gd")

var world: Node3D
var hud: CanvasLayer
var prompt_label: Label
var mode_panel: Panel
var mode_title: Label
var mode_body: Label
var seen_interaction := ""

func _ready() -> void:
	_build_render_environment()
	world = StoreWorld.new()
	world.name = "StoreWorld3D"
	add_child(world)
	_build_hud()
	print("PC GAME EMPIRE M0: REAL GAME MAIN READY")

func _process(_delta: float) -> void:
	if world == null: return
	prompt_label.text = "" if String(world.prompt_text).is_empty() else "[E]  " + String(world.prompt_text)
	var interaction := String(world.last_interaction)
	if interaction != "" and interaction != seen_interaction:
		seen_interaction = interaction
		_handle_interaction(interaction)
	if Input.is_action_just_pressed("cancel") and mode_panel.visible:
		_close_mode()

func _build_render_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0c1118")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8aa2b8")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env_node.environment = env
	add_child(env_node)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-58,-32,0)
	key.light_color = Color("#d7e6f2")
	key.light_energy = 0.72
	key.shadow_enabled = true
	add_child(key)

func _build_hud() -> void:
	hud = CanvasLayer.new(); hud.name = "HUD"; add_child(hud)
	var top := Panel.new(); top.position=Vector2(24,20); top.size=Vector2(720,76); hud.add_child(top)
	var title:=Label.new(); title.position=Vector2(24,14); title.text="PC GAME EMPIRE  •  TECHNICAL REAL-WORLD SLICE"; title.add_theme_font_size_override("font_size",22); top.add_child(title)
	var status:=Label.new(); status.position=Vector2(24,45); status.text="MONDO 3D REALE • WASD/FRECCE • E INTERAGISCI"; status.add_theme_font_size_override("font_size",13); top.add_child(status)
	prompt_label=Label.new(); prompt_label.position=Vector2(720,940); prompt_label.size=Vector2(480,58); prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; prompt_label.add_theme_font_size_override("font_size",22); hud.add_child(prompt_label)
	mode_panel=Panel.new(); mode_panel.position=Vector2(360,150); mode_panel.size=Vector2(1200,760); mode_panel.visible=false; hud.add_child(mode_panel)
	mode_title=Label.new(); mode_title.position=Vector2(48,38); mode_title.add_theme_font_size_override("font_size",32); mode_panel.add_child(mode_title)
	mode_body=Label.new(); mode_body.position=Vector2(48,105); mode_body.size=Vector2(1100,570); mode_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; mode_body.add_theme_font_size_override("font_size",20); mode_panel.add_child(mode_body)
	var close:=Label.new(); close.position=Vector2(48,700); close.text="ESC  TORNA AL NEGOZIO"; close.add_theme_font_size_override("font_size",16); mode_panel.add_child(close)

func _handle_interaction(id: String) -> void:
	match id:
		"store_pc":
			_open_mode("SHOP HARDWARE", "Questa finestra è collegata al PC fisico del negozio.\n\nLa UI commerciale definitiva riutilizzerà catalogo, prezzi, compatibilità e inventario già esistenti.\n\nQuesto pannello nella Milestone 0 serve esclusivamente a provare che il terminale del mondo reale apre davvero il sistema Shop.")
		"workbench":
			_open_mode("BANCO ASSEMBLAGGIO", "Il banco è un oggetto fisico del laboratorio.\n\nMilestone 0: collegamento runtime verificabile al modulo Assembly.\nLa logica drag&drop/compatibilità della vecchia Milestone A verrà reintegrata qui dopo il gate del mondo reale.")
		"diagnostics":
			_open_mode("DIAGNOSTICA", "Terminale diagnostico fisicamente presente nel laboratorio.\nIl sistema completo viene reintegrato nella Milestone B dopo la validazione del world layer.")
		"counter":
			_open_mode("PRIMO CLIENTE", "Il cliente è un CharacterBody3D reale: entra dal negozio, cammina verso il bancone e attende.\n\nDialogo tutorial/storyline verrà agganciato a questo NPC, non a un hotspot su un fondale.")
		"lab_door":
			seen_interaction = ""

func _open_mode(title: String, body: String) -> void:
	mode_title.text=title; mode_body.text=body; mode_panel.visible=true
	if world.player != null: world.player.set_physics_process(false)

func _close_mode() -> void:
	mode_panel.visible=false
	if world.player != null: world.player.set_physics_process(true)
	seen_interaction=""
	world.last_interaction=""

func technical_status() -> Dictionary:
	var status:Dictionary = world.technical_status() if world != null else {}
	status["shop_ui_connected"] = mode_panel != null
	status["main_scene_real_time"] = true
	return status
