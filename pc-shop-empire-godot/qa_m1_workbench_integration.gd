extends SceneTree

const Game=preload("res://game/real_game_main.gd")
var failures:Array[String]=[]

func check(condition:bool,message:String)->void:
	if condition: print("M1 WORKBENCH PASS: ",message)
	else: failures.append(message); printerr("M1 WORKBENCH FAIL: ",message)

func _init()->void: call_deferred("run")

func run()->void:
	var game=Game.new(); root.add_child(game)
	await process_frame; await process_frame
	check(game.assembly_ui!=null,"real-world HUD owns assembly workbench")
	check(game.assembly_ui.core!=null and game.assembly_ui.core.components.size()>=30,"workbench uses real AssemblyCore catalogue")
	game._handle_interaction("workbench")
	check(game.assembly_ui.visible,"physical workbench opens functional assembly UI")
	check(not game.world.player.is_physics_processing(),"player pauses while using workbench")
	var ui=game.assembly_ui
	check(bool(ui.install_component("case_atx").get("ok",false)),"case installs through workbench UI")
	check(bool(ui.install_component("mb_b850").get("ok",false)),"motherboard installs through workbench UI")
	check(not bool(ui.install_component("cpu_14600kf").get("ok",true)),"workbench displays real compatibility rejection")
	for id:String in ["cpu_9600x","ram_32","ssd_1tb","psu_750","gpu_5060"]: check(bool(ui.install_component(id).get("ok",false)),"workbench installs "+id)
	check(bool(ui.perform_action("paste").get("ok",false)),"workbench applies thermal paste")
	check(bool(ui.install_component("cooler_air").get("ok",false)),"workbench installs cooler")
	check(bool(ui.perform_action("paste").get("ok",false)),"workbench reapplies paste after seating cooler")
	check(bool(ui.perform_action("cables").get("ok",false)),"workbench connects cables")
	check(bool(ui.perform_action("panel").get("ok",false)),"workbench closes case panel")
	check(ui.core.build_ready() and not ui.complete_button.disabled,"complete action unlocks only for a ready machine")
	check(bool(ui.perform_action("complete").get("ok",false)),"workbench completes compatible build")
	ui.close_workbench(); await process_frame
	check(not ui.visible and game.world.player.is_physics_processing(),"closing workbench resumes real player")
	game.queue_free(); await process_frame
	if failures.is_empty(): print("PC GAME EMPIRE M1 WORKBENCH INTEGRATION QA: ALL TESTS PASSED"); quit(0)
	else: printerr("PC GAME EMPIRE M1 WORKBENCH INTEGRATION QA: ",failures.size()," FAILURE(S)"); quit(1)
