extends SceneTree

const SaveProgressAdapter := preload("res://scripts/systems/save_progress_adapter.gd")

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		printerr("SMOKE_FAIL: " + message)

func _run() -> void:
	var splash_resource := load("res://scenes/startup/splash_loader.tscn") as PackedScene
	_check(splash_resource != null, "Splash Loader PackedScene must load")
	if splash_resource != null:
		var splash_instance := splash_resource.instantiate()
		_check(splash_instance.has_node("IdentityLayer/JOSESIWordmark/OLogo"), "Splash official O logo node missing")
		_check(splash_instance.has_node("LoaderLayer/TraceLoader"), "Splash Journey Trace node missing")
		_check(splash_instance.has_node("OverlayLayer/WarningErrorPanel"), "Splash recovery overlay missing")
		splash_instance.free()

	var first_launch := SaveProgressAdapter.first_launch_model()
	_check(first_launch.get("has_valid_save", true) == false, "First launch model must not fabricate a save")
	_check(first_launch.get("portfolio_count", -1) == 0, "First launch portfolio count must be zero")
	var stages: Dictionary = first_launch.get("stage_states", {})
	_check(stages.get("SEE", "") == "AVAILABLE", "SEE must be AVAILABLE on first launch")
	_check(stages.get("EXPLORE", "") == "LOCKED", "EXPLORE must be LOCKED on first launch")

	var menu_resource := load("res://scenes/menu/main_menu.tscn") as PackedScene
	_check(menu_resource != null, "Main Menu PackedScene must load")
	if menu_resource != null:
		var menu := menu_resource.instantiate()
		root.add_child(menu)
		await process_frame
		menu.set("_model", first_launch)
		menu.set("_state", "FIRST_LAUNCH")
		menu.call("_apply_state")
		var primary := menu.get_node("SafeArea/NavigationColumn/PrimaryCTA") as Button
		var new_journey := menu.get_node("SafeArea/NavigationColumn/NewJourneyButton") as Button
		var portfolio := menu.get_node("SafeArea/NavigationColumn/PortfolioButton") as Button
		var panel := menu.get_node("CurrentJourneyPanel") as PanelContainer
		_check(primary.text == "MULAI PERJALANAN", "First launch CTA must be MULAI PERJALANAN")
		_check(not new_journey.visible, "New Journey must be hidden on first launch")
		_check(not portfolio.visible, "Portfolio must be hidden on first launch")
		_check(not panel.visible, "Current Journey panel must be hidden on first launch")
		var settings := menu.get_node("SafeArea/NavigationColumn/SettingsButton") as Button
		settings.pressed.emit()
		await process_frame
		_check(menu.get_node("OverlayLayer/SettingsOverlay").visible, "Settings overlay must open")
		menu.get_node("OverlayLayer/SettingsOverlay/Panel/PanelMargin/Content/CloseButton").pressed.emit()
		await process_frame
		_check(not menu.get_node("OverlayLayer/SettingsOverlay").visible, "Settings overlay must close")
		var progress_control := menu.get_node("CurrentJourneyPanel/PanelMargin/PanelHBox/StageProgress") as Control
		_check(progress_control.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Stage progress must be noninteractive")
		root.remove_child(menu)
		menu.free()

	if _failures.is_empty():
		print("JOSESI_01_SMOKE_TEST=PASS")
		quit(0)
	else:
		printerr("JOSESI_01_SMOKE_TEST=FAIL count=%d" % _failures.size())
		quit(1)
