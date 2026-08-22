extends Node

const StoreWorld = preload("res://game/world/store_world_3d_runtime.gd")
const CustomerFactory = preload("res://game/world/customer_factory_3d.gd")
const CustomerScript = preload("res://game/world/customer_3d.gd")
const ActorVisual = preload("res://game/world/stylized_actor_visual.gd")

var world: Node3D
var ambient_customers:Array[CharacterBody3D] = []
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
	ambient_customers=CustomerFactory.spawn_ambient_set(world,CustomerScript,ActorVisual)
	_build_hud()
	print("PC GAME EMPIRE M0: REAL GAME MAIN READY")

func _process(_delta: float) -> void:
	if world == null: return
	prompt_label.text = "" if String(world.prompt_text).is_empty() else "E  •  " + String(world.prompt_text)
	var interaction := String(world.last_interaction)
	if interaction != "" and interaction != seen_interaction:
		seen_interaction = interaction
		_handle_interaction(interaction)
	if Input.is_action_just_pressed("cancel") and mode_panel.visible:
		_close_mode()

func _build_render_environment() -> void:
	var env_node := WorldEnvironment.new(); env_node.name="PCGEWorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101722")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a5b7c7")
	env.ambient_light_energy = 0.68
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.glow_enabled = true
	env.glow_intensity = 0.52
	env.glow_strength = 0.85
	env_node.environment = env
	add_child(env_node)
	var key := DirectionalLight3D.new(); key.name="KeyLight"
	key.rotation_degrees = Vector3(-56,-34,0)
	key.light_color = Color("#e3edf5")
	key.light_energy = 0.86
	key.shadow_enabled = true
	key.directional_shadow_max_distance=34.0
	add_child(key)
	var fill := DirectionalLight3D.new(); fill.name="FillLight"
	fill.rotation_degrees=Vector3(-48,132,0)
	fill.light_color=Color("#83b7d4")
	fill.light_energy=0.24
	fill.shadow_enabled=false
	add_child(fill)
	var rim:=DirectionalLight3D.new(); rim.name="WarmRim"
	rim.rotation_degrees=Vector3(-35,-145,0)
	rim.light_color=Color("#e34a65")
	rim.light_energy=0.13
	rim.shadow_enabled=false
	add_child(rim)

func _panel_style(bg:Color,border:Color,radius:int=10)->StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=bg; style.border_color=border
	style.set_border_width_all(1); style.corner_radius_top_left=radius; style.corner_radius_top_right=radius; style.corner_radius_bottom_left=radius; style.corner_radius_bottom_right=radius
	style.shadow_color=Color(0,0,0,0.38); style.shadow_size=8
	return style

func _build_hud() -> void:
	hud = CanvasLayer.new(); hud.name = "HUD"; add_child(hud)
	var top := Panel.new(); top.name="StatusHUD"; top.position=Vector2(24,20); top.size=Vector2(650,78); top.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.050,0.070,0.90),Color(0.25,0.34,0.42,0.82),12)); hud.add_child(top)
	var brand:=Label.new(); brand.position=Vector2(20,10); brand.text="PC GAME EMPIRE"; brand.add_theme_font_size_override("font_size",21); brand.add_theme_color_override("font_color",Color("#f3f7fa")); top.add_child(brand)
	var status:=Label.new(); status.position=Vector2(20,42); status.text="GIORNO 1   •   € 2.000   •   REPUTAZIONE 0   •   SMALL SHOP"; status.add_theme_font_size_override("font_size",13); status.add_theme_color_override("font_color",Color("#a9becd")); top.add_child(status)
	var objective:=Panel.new(); objective.position=Vector2(24,112); objective.size=Vector2(420,54); objective.add_theme_stylebox_override("panel",_panel_style(Color(0.045,0.060,0.080,0.86),Color(0.72,0.16,0.26,0.82),10)); hud.add_child(objective)
	var objective_label:=Label.new(); objective_label.position=Vector2(16,9); objective_label.text="OBIETTIVO  •  Parla con il primo cliente"; objective_label.add_theme_font_size_override("font_size",15); objective_label.add_theme_color_override("font_color",Color("#f0f4f7")); objective.add_child(objective_label)
	prompt_label=Label.new(); prompt_label.position=Vector2(700,954); prompt_label.size=Vector2(520,54); prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; prompt_label.add_theme_font_size_override("font_size",20); prompt_label.add_theme_color_override("font_color",Color("#ffffff")); prompt_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85)); prompt_label.add_theme_constant_override("shadow_offset_x",2); prompt_label.add_theme_constant_override("shadow_offset_y",2); hud.add_child(prompt_label)
	mode_panel=Panel.new(); mode_panel.position=Vector2(390,165); mode_panel.size=Vector2(1140,720); mode_panel.visible=false; mode_panel.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.048,0.065,0.97),Color(0.28,0.38,0.47,0.95),16)); hud.add_child(mode_panel)
	mode_title=Label.new(); mode_title.position=Vector2(48,36); mode_title.add_theme_font_size_override("font_size",32); mode_title.add_theme_color_override("font_color",Color("#f5f8fa")); mode_panel.add_child(mode_title)
	var divider:=ColorRect.new(); divider.position=Vector2(48,88); divider.size=Vector2(1044,2); divider.color=Color("#b92443"); mode_panel.add_child(divider)
	mode_body=Label.new(); mode_body.position=Vector2(48,118); mode_body.size=Vector2(1044,500); mode_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; mode_body.add_theme_font_size_override("font_size",19); mode_body.add_theme_color_override("font_color",Color("#c7d4dd")); mode_panel.add_child(mode_body)
	var close:=Label.new(); close.position=Vector2(48,655); close.text="ESC  •  TORNA AL NEGOZIO"; close.add_theme_font_size_override("font_size",15); close.add_theme_color_override("font_color",Color("#e83a5b")); mode_panel.add_child(close)

func _handle_interaction(id: String) -> void:
	match id:
		"store_pc":
			_open_mode("SHOP HARDWARE", "Terminale fisico del negozio collegato al catalogo hardware.\n\nMilestone 0 verifica il mondo reale e l'interazione. Catalogo, prezzi, compatibilità e inventario completi vengono reintegrati nella relativa milestone del nuovo mondo.")
		"workbench":
			_open_mode("BANCO ASSEMBLAGGIO", "Banco fisico del laboratorio collegato al modulo Assembly.\n\nLa logica drag & drop e compatibilità valida della vecchia build verrà reintegrata qui dopo la chiusura di Milestone 0.")
		"diagnostics":
			_open_mode("DIAGNOSTICA", "Postazione diagnostica fisicamente presente nel laboratorio.\n\nIl sistema completo di riparazioni e benchmark appartiene alla Milestone B.")
		"counter":
			_open_mode("PRIMO CLIENTE", "Il cliente è entrato realmente nel negozio, ha percorso la scena e ora attende al bancone.\n\nQuesto punto diventerà il primo dialogo tutorial della carriera.")
			var customer_visual:=world.customer.get_node_or_null("CustomerVisual") if world.customer!=null else null
			if customer_visual!=null and customer_visual.has_method("play_action"): customer_visual.play_action("talk",0.9)
		"lab_door": seen_interaction = ""

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
	status["ambient_customer_count"] = ambient_customers.size()
	return status
