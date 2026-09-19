extends SceneTree

func _initialize() -> void:
	var scene := load("res://scenes/menu/main_menu.tscn") as PackedScene
	if scene == null:
		push_error("JOSESI_01_SMOKE_TEST=FAIL reason=main_menu_scene_missing")
		quit(1)
		return

	var menu := scene.instantiate()
	root.add_child(menu)
	await process_frame

	var ok := true
	ok = ok and menu.has_method("get_menu_state_name")
	ok = ok and menu.has_node("SafeArea/LeftColumn/MenuBlock/PrimaryButton")
	ok = ok and menu.has_node("SafeArea/BottomDock/JourneyPanel/HBox/StageProgress")

	if not ok:
		push_error("JOSESI_01_SMOKE_TEST=FAIL reason=required_nodes_missing")
		quit(1)
		return

	print("JOSESI_MAIN_MENU_READY=TRUE state=%s" % menu.call("get_menu_state_name"))
	print("JOSESI_01_SMOKE_TEST=PASS")
	quit(0)