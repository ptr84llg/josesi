extends SceneTree

const REQUIRED_ASSETS := [
    "res://assets/runtime/menu_environment_master.png",
    "res://assets/runtime/splash_visual_master.png",
    "res://assets/branding/josesi_wordmark_letters.png",
    "res://assets/ui/icons/play.svg",
    "res://assets/ui/icons/new_journey.svg",
    "res://assets/ui/icons/portfolio.svg",
    "res://assets/ui/icons/settings.svg",
    "res://assets/ui/icons/about.svg",
    "res://assets/ui/icons/exit.svg",
]

const LEGACY_PATHS := [
    "res://assets/menu/world_panorama_concept_reference.png",
    "res://assets/fonts/Fredoka-VariableFont_wdth,wght.ttf",
    "res://scripts/systems/settings_store.gd",
]

func _initialize() -> void:
    var failures: Array[String] = []

    for path in REQUIRED_ASSETS:
        if not FileAccess.file_exists(path):
            failures.append("missing:" + path)

    for path in LEGACY_PATHS:
        if FileAccess.file_exists(path):
            failures.append("legacy-present:" + path)

    var main_scene := load("res://scenes/menu/main_menu.tscn") as PackedScene
    var splash_scene := load("res://scenes/startup/splash_loader.tscn") as PackedScene
    if main_scene == null:
        failures.append("main-scene-unloadable")
    if splash_scene == null:
        failures.append("splash-scene-unloadable")

    if main_scene != null:
        var menu := main_scene.instantiate()
        root.add_child(menu)
        await process_frame
        if not menu.has_node("BackgroundWorld/Panorama"):
            failures.append("menu-background-master-missing")
        if not menu.has_node("SafeArea/LeftColumn/BrandBlock/JosesiWordmark/Letters"):
            failures.append("menu-raster-wordmark-missing")
        if not menu.has_node("SafeArea/LeftColumn/BrandBlock/JosesiWordmark/OLogo"):
            failures.append("menu-official-o-logo-missing")
        if menu.has_node("SafeArea/JourneyTrace"):
            failures.append("legacy-menu-journey-trace-node-present")
        menu.queue_free()

    if splash_scene != null:
        var splash := splash_scene.instantiate()
        root.add_child(splash)
        await process_frame
        if not splash.has_node("Background/VisualMaster"):
            failures.append("splash-visual-master-missing")
        if splash.has_node("Background/Panorama"):
            failures.append("legacy-splash-panorama-node-present")
        splash.queue_free()

    if failures.is_empty():
        print("JOSESI_01_REBUILD_CONTRACT=PASS")
        quit(0)
        return

    print("JOSESI_01_REBUILD_CONTRACT=RED_EXPECTED")
    for failure in failures:
        print("REBUILD_CONTRACT_FAILURE=" + failure)
    quit(2)
