extends Control

signal closed
signal build_completed(snapshot:Dictionary)

const AssemblyCore=preload("res://game/systems/assembly_core.gd")

var core:RefCounted
var inventory_list:VBoxContainer
var slots_list:VBoxContainer
var feedback_label:Label
var totals_label:Label
var readiness_label:Label
var panel_button:Button
var complete_button:Button
var last_result:Dictionary={}

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	_build_interface()
	visible=false

func initialize()->bool:
	core=AssemblyCore.new()
	if not core.load_component_database(): return false
	core.begin_build()
	for item:Dictionary in core.components: core.add_inventory(String(item.get("id","")),1)
	_refresh()
	return true

func open_workbench()->void:
	if core==null: initialize()
	visible=true
	_refresh()

func close_workbench()->void:
	visible=false
	closed.emit()

func install_component(id:String)->Dictionary:
	last_result=core.install(id)
	_refresh(String(last_result.get("message","")),bool(last_result.get("ok",false)))
	return last_result

func remove_component(category:String)->Dictionary:
	last_result=core.remove(category)
	_refresh(String(last_result.get("message","")),bool(last_result.get("ok",false)))
	return last_result

func perform_action(action:String)->Dictionary:
	match action:
		"panel": last_result=core.toggle_case_panel()
		"paste": last_result=core.apply_thermal_paste()
		"cables": last_result=core.connect_cables()
		"complete":
			if core.build_ready():
				last_result={"ok":true,"message":"PC completato e pronto per il collaudo"}
				build_completed.emit(core.snapshot())
			else: last_result={"ok":false,"message":"Assemblaggio incompleto: controlla componenti, pasta, cavi e pannello"}
		_: last_result={"ok":false,"message":"Azione sconosciuta"}
	_refresh(String(last_result.get("message","")),bool(last_result.get("ok",false)))
	return last_result

func _unhandled_input(event:InputEvent)->void:
	if visible and event.is_action_pressed("cancel"):
		close_workbench(); get_viewport().set_input_as_handled()

func _build_interface()->void:
	var shade:=ColorRect.new(); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color=Color(0.015,0.022,0.032,0.94); add_child(shade)
	var header:=Panel.new(); header.position=Vector2(34,26); header.size=Vector2(1852,92); header.add_theme_stylebox_override("panel",_style(Color("#101925"),Color("#d62f51"),14)); add_child(header)
	var title:=Label.new(); title.position=Vector2(28,14); title.text="PC GAME EMPIRE  /  ASSEMBLY WORKBENCH"; title.add_theme_font_size_override("font_size",28); title.add_theme_color_override("font_color",Color("#f4f7fa")); header.add_child(title)
	var subtitle:=Label.new(); subtitle.position=Vector2(30,52); subtitle.text="Monta il PC in ordine, verifica la compatibilità e completa le operazioni tecniche."; subtitle.add_theme_font_size_override("font_size",15); subtitle.add_theme_color_override("font_color",Color("#91a9ba")); header.add_child(subtitle)
	var exit:=Button.new(); exit.position=Vector2(1680,20); exit.size=Vector2(140,48); exit.text="ESC  ESCI"; exit.pressed.connect(close_workbench); header.add_child(exit)

	var inventory_panel:=Panel.new(); inventory_panel.position=Vector2(34,138); inventory_panel.size=Vector2(650,830); inventory_panel.add_theme_stylebox_override("panel",_style(Color("#0b121c"),Color("#26394a"),12)); add_child(inventory_panel)
	_add_heading(inventory_panel,"COMPONENTI DISPONIBILI",Vector2(24,18),Color("#51c8ed"))
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(20,62); scroll.size=Vector2(610,746); inventory_panel.add_child(scroll)
	inventory_list=VBoxContainer.new(); inventory_list.custom_minimum_size=Vector2(586,0); inventory_list.add_theme_constant_override("separation",7); scroll.add_child(inventory_list)

	var build_panel:=Panel.new(); build_panel.position=Vector2(704,138); build_panel.size=Vector2(650,830); build_panel.add_theme_stylebox_override("panel",_style(Color("#0c141f"),Color("#493344"),12)); add_child(build_panel)
	_add_heading(build_panel,"CASE / SLOT DI ASSEMBLAGGIO",Vector2(24,18),Color("#ee4968"))
	slots_list=VBoxContainer.new(); slots_list.position=Vector2(24,66); slots_list.size=Vector2(602,508); slots_list.add_theme_constant_override("separation",8); build_panel.add_child(slots_list)
	feedback_label=Label.new(); feedback_label.position=Vector2(24,592); feedback_label.size=Vector2(602,72); feedback_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; feedback_label.add_theme_font_size_override("font_size",16); build_panel.add_child(feedback_label)
	totals_label=Label.new(); totals_label.position=Vector2(24,678); totals_label.size=Vector2(602,34); totals_label.add_theme_font_size_override("font_size",18); totals_label.add_theme_color_override("font_color",Color("#dfe8ee")); build_panel.add_child(totals_label)
	readiness_label=Label.new(); readiness_label.position=Vector2(24,722); readiness_label.size=Vector2(602,34); readiness_label.add_theme_font_size_override("font_size",18); build_panel.add_child(readiness_label)

	var action_panel:=Panel.new(); action_panel.position=Vector2(1374,138); action_panel.size=Vector2(512,830); action_panel.add_theme_stylebox_override("panel",_style(Color("#0b121c"),Color("#26394a"),12)); add_child(action_panel)
	_add_heading(action_panel,"OPERAZIONI TECNICHE",Vector2(24,18),Color("#f0f4f7"))
	var guide:=Label.new(); guide.position=Vector2(24,68); guide.size=Vector2(464,180); guide.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; guide.text="1. Installa il case\n2. Monta motherboard, CPU e RAM\n3. Applica la pasta termica\n4. Installa dissipatore e hardware\n5. Collega i cavi\n6. Chiudi il pannello"; guide.add_theme_font_size_override("font_size",17); guide.add_theme_color_override("font_color",Color("#adc0cd")); action_panel.add_child(guide)
	panel_button=_action_button(action_panel,"APRI / CHIUDI PANNELLO",Vector2(24,282),"panel")
	_action_button(action_panel,"APPLICA PASTA TERMICA",Vector2(24,352),"paste")
	_action_button(action_panel,"COLLEGA CAVI",Vector2(24,422),"cables")
	complete_button=_action_button(action_panel,"COMPLETA ASSEMBLAGGIO",Vector2(24,520),"complete"); complete_button.add_theme_color_override("font_color",Color("#ffffff"))
	var rule:=Label.new(); rule.position=Vector2(24,606); rule.size=Vector2(464,160); rule.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; rule.text="La compatibilità è calcolata sui dati reali dei componenti: socket, RAM, form factor, lunghezza GPU, potenza PSU e ingombro del raffreddamento."; rule.add_theme_font_size_override("font_size",15); rule.add_theme_color_override("font_color",Color("#738b9c")); action_panel.add_child(rule)

func _refresh(message:String="",success:bool=true)->void:
	if core==null or inventory_list==null: return
	_clear(inventory_list); _clear(slots_list)
	var previous_category:=""
	for item:Dictionary in core.components:
		var id:=String(item.get("id","")); var quantity:=int(core.inventory.get(id,0))
		if quantity<=0: continue
		var category:=String(item.get("category",""))
		if category!=previous_category:
			var category_label:=Label.new(); category_label.text=category.to_upper(); category_label.add_theme_font_size_override("font_size",14); category_label.add_theme_color_override("font_color",Color("#55c9ed")); inventory_list.add_child(category_label); previous_category=category
		var button:=Button.new(); button.custom_minimum_size=Vector2(570,48); button.text="%s   •   € %d"%[String(item.get("name",id)),int(item.get("price",0))]; button.alignment=HORIZONTAL_ALIGNMENT_LEFT; button.tooltip_text=_component_details(item); button.pressed.connect(install_component.bind(id)); inventory_list.add_child(button)
	for category:String in AssemblyCore.DEFAULT_REQUIRED:
		var row:=Panel.new(); row.custom_minimum_size=Vector2(602,52); row.add_theme_stylebox_override("panel",_style(Color("#111d29"),Color("#263b4c"),7)); slots_list.add_child(row)
		var category_label:=Label.new(); category_label.position=Vector2(14,8); category_label.size=Vector2(150,34); category_label.text=category.to_upper(); category_label.add_theme_font_size_override("font_size",14); category_label.add_theme_color_override("font_color",Color("#8298a8")); row.add_child(category_label)
		var installed:=Label.new(); installed.position=Vector2(168,8); installed.size=Vector2(310,34); installed.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; installed.add_theme_font_size_override("font_size",15)
		if core.slots.has(category):
			installed.text=String(core.component(String(core.slots[category])).get("name",core.slots[category])); installed.add_theme_color_override("font_color",Color("#eff5f8"))
			var remove:=Button.new(); remove.position=Vector2(492,7); remove.size=Vector2(96,38); remove.text="RIMUOVI"; remove.tooltip_text="Rimuovi il componente e restituiscilo all'inventario"; remove.pressed.connect(remove_component.bind(category)); row.add_child(remove)
		else: installed.text="— slot vuoto —"; installed.add_theme_color_override("font_color",Color("#5f7281"))
		row.add_child(installed)
	feedback_label.text=message if not message.is_empty() else "Seleziona un componente dall'inventario. Le installazioni incompatibili vengono bloccate."
	feedback_label.add_theme_color_override("font_color",Color("#56d5a0") if success else Color("#ff607b"))
	totals_label.text="VALORE BUILD  € %d     •     SCORE  %d"%[core.build_cost(),core.build_score()]
	var ready:bool=bool(core.build_ready()); readiness_label.text="PRONTO AL COLLAUDO" if ready else "ASSEMBLAGGIO IN CORSO"; readiness_label.add_theme_color_override("font_color",Color("#54d69b") if ready else Color("#edbc62")); complete_button.disabled=not ready
	panel_button.text="CHIUDI PANNELLO" if core.case_panel_open else "APRI PANNELLO"

func _component_details(item:Dictionary)->String:
	var details:=PackedStringArray([String(item.get("category",""))])
	for key:String in ["socket","ram","form","watts","power","length","kind","radiator","height"]:
		if item.has(key): details.append("%s: %s"%[key,str(item[key])])
	return "  •  ".join(details)

func _action_button(parent:Control,text_value:String,position_value:Vector2,action:String)->Button:
	var button:=Button.new(); button.position=position_value; button.size=Vector2(464,54); button.text=text_value; button.pressed.connect(perform_action.bind(action)); parent.add_child(button); return button

func _add_heading(parent:Control,text_value:String,position_value:Vector2,color:Color)->void:
	var label:=Label.new(); label.position=position_value; label.text=text_value; label.add_theme_font_size_override("font_size",20); label.add_theme_color_override("font_color",color); parent.add_child(label)

func _clear(container:Node)->void:
	for child:Node in container.get_children(): child.queue_free()

func _style(bg:Color,border:Color,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=bg; style.border_color=border; style.set_border_width_all(1); style.set_corner_radius_all(radius); return style
