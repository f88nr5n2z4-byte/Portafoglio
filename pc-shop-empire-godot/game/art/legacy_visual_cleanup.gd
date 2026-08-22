extends Node3D

# Removes only the visible greybox furniture from the original technical world.
# StaticBody3D collision geometry and architectural physics are deliberately untouched.
const EXACT_NAMES := {
	"ServiceCounter": true,
	"CounterTop": true,
	"DisplayTable": true,
	"DisplayAccent": true,
	"PCCase": true,
	"PCGlass": true,
	"PCFan": true,
	"MonitorStand": true,
	"Monitor": true,
	"StoreTerminalDesk": true,
	"Workbench": true,
	"WorkbenchTop": true,
	"DiagnosticDesk": true,
	"ProductBox": true
}

func _ready() -> void:
	call_deferred("_hide_legacy_visuals")

func _hide_legacy_visuals() -> void:
	var world:=get_parent()
	if world==null: return
	var hidden:=0
	for child in world.get_children():
		if not (child is MeshInstance3D): continue
		var n:=String(child.name)
		if EXACT_NAMES.has(n) or n.begins_with("Shelf_"):
			child.visible=false
			hidden+=1
	print("M0 LEGACY VISUAL CLEANUP: hidden ",hidden," greybox meshes; physics preserved")
