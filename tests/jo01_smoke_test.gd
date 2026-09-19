extends SceneTree

func _initialize() -> void:
	var menu_scene := load("res://scenes/menu/main_menu.tscn") as PackedScene
	var splash_scene := load("res://scenes/startup/splash_loader.tscn") as PackedScene
	if menu_scene == null or splash_scene == null:
		push_error("JOSESI_01_SMOKE_TEST=FAIL reason=scene_load_failed")
		quit(1)
		return

	var splash := splash_scene.instantiate()
	root.add_child(splash)
	await process_frame
	await process_frame

	var splash_ok := splash.has_node("Background/Environment")
	splash_ok = splash_ok and splash.has_node("SafeArea/Wordmark")
	splash_ok = splash_ok and splash.has_node("SafeArea/ContentStack/LoaderStack/JourneyTrace")
	splash_ok = splash_ok and splash.has_method("is_target_scene_ready")
	splash_ok = splash_ok and bool(splash.call("is_target_scene_ready"))
	if not splash_ok:
		splash.free()
		await process_frame
		push_error("JOSESI_01_SMOKE_TEST=FAIL reason=splash_runtime_loader_not_ready")
		quit(1)
		return

	print("JOSESI_SPLASH_SMOKE_READY=TRUE")
	splash.free()
	await process_frame
	await process_frame

	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var menu_ok := menu.has_method("get_menu_state_name")
	menu_ok = menu_ok and menu.has_node("BackgroundWorld/Environment")
	menu_ok = menu_ok and menu.has_node("BackgroundWorld/WorldJourneyTrace")
	menu_ok = menu_ok and menu.has_node("SafeArea/RightPortal/MenuStack/PrimaryButton")
	menu_ok = menu_ok and menu.has_node("SafeArea/JourneyDock/StageProgress")
	if not menu_ok:
		menu.free()
		await process_frame
		push_error("JOSESI_01_SMOKE_TEST=FAIL reason=menu_required_nodes_missing")
		quit(1)
		return

	var state_name := str(menu.call("get_menu_state_name"))
	menu.free()
	menu = null
	menu_scene = null
	splash_scene = null

	# Let RenderingServer/TextServer process the removals before terminating
	# the headless SceneTree. This prevents false leak diagnostics caused by
	# quitting in the same frame as live Control/Font/Texture resources.
	await process_frame
	await process_frame

	print("JOSESI_MAIN_MENU_READY=TRUE state=%s" % state_name)
	print("JOSESI_01_SMOKE_TEST=PASS")
	quit(0)
