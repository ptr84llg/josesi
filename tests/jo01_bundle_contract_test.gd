extends SceneTree

const REQUIRED_FILES := [
	"res://assets/backgrounds/splash/background_splash_loader.png",
	"res://assets/backgrounds/menu/background_main_menu.png",
	"res://assets/branding/JOSESI.png",
	"res://assets/fonts/Manrope-VariableFont_wght.ttf",
	"res://assets/ui/buttons/primary.png",
	"res://assets/ui/buttons/secondary.png",
	"res://assets/ui/panels/modal.png",
	"res://assets/ui/panels/journey_dock.png",
	"res://assets/ui/icons/play.png",
	"res://assets/ui/icons/restart.png",
	"res://assets/ui/icons/portfolio.png",
	"res://assets/ui/icons/settings.png",
	"res://assets/ui/icons/about.png",
	"res://assets/ui/icons/exit.png",
	"res://assets/ui/icons/chevron.png",
	"res://assets/ui/icons/complete.png",
	"res://assets/ui/icons/current.png",
	"res://assets/ui/icons/locked.png",
	"res://assets/ui/icons/notification.png",
	"res://assets/ui/journey/menu_trace.png",
	"res://assets/ui/journey/node_available.png",
	"res://assets/ui/journey/splash_trace_fill.png",
	"res://assets/ui/journey/splash_trace_track.png",
	"res://scenes/ui/josesi_wordmark.tscn",
	"res://scenes/ui/action_button.tscn",
	"res://scenes/ui/journey_trace.tscn",
	"res://scenes/ui/stage_progress_strip.tscn",
]

const FORBIDDEN_FILES := [
	"res://assets/runtime/splash_visual_master.png",
	"res://assets/runtime/menu_environment_master.png",
	"res://assets/branding/josesi_wordmark_letters.png",
	"res://assets/branding/logo_dkv_unpari_official.png",
	"res://assets/ui/icons/play.svg",
	"res://assets/ui/icons/settings.svg",
	"res://assets/ui/icons/about.svg",
	"res://assets/ui/icons/exit.svg",
	"res://scripts/ui/stage_progress_indicator.gd",
	"res://tests/jo01_rebuild_contract_test.gd",
	"res://preview_splash_loader_v1.png",
	"res://preview_main_menu_v1.png",
	"res://ui-01.png",
	"res://ui-02.png",
	"res://ui-03.png",
	"res://ui-04.png",
	"res://ui-05.png",
	"res://ui-06.png",
]

const IMMUTABLE_HASHES := {
	"res://assets/branding/JOSESI.png": "01ae78d87057ba53752a646a786224e1cc20fcda8cfa94127aac0a88529717f2",
	"res://assets/backgrounds/splash/background_splash_loader.png": "5f9209ce5097b5ebccee2aefd506a302785050ce1602024f5dd2cf04e0f7ae5d",
	"res://assets/backgrounds/menu/background_main_menu.png": "b001ef702414d71cb3d8ac711e968e9bb6a3b58387b30f676661a91a511aff93",
}

func _initialize() -> void:
	var failures: Array[String] = []

	for path in REQUIRED_FILES:
		if not FileAccess.file_exists(path):
			failures.append("missing:" + path)

	for path in FORBIDDEN_FILES:
		if FileAccess.file_exists(path):
			failures.append("forbidden-present:" + path)

	for path in IMMUTABLE_HASHES.keys():
		if FileAccess.file_exists(path):
			var actual := FileAccess.get_sha256(path).to_lower()
			var expected := str(IMMUTABLE_HASHES[path]).to_lower()
			if actual != expected:
				failures.append("hash-mismatch:%s expected=%s actual=%s" % [path, expected, actual])

	var splash_text := FileAccess.get_file_as_string("res://scenes/startup/splash_loader.tscn")
	var menu_text := FileAccess.get_file_as_string("res://scenes/menu/main_menu.tscn")
	var wordmark_text := FileAccess.get_file_as_string("res://scenes/ui/josesi_wordmark.tscn")

	if "background_splash_loader.png" not in splash_text:
		failures.append("splash-background-not-bundle-source")
	if "splash_visual_master.png" in splash_text:
		failures.append("splash-mockup-master-reference-present")
	if "background_main_menu.png" not in menu_text:
		failures.append("menu-background-not-bundle-source")
	if "menu_environment_master.png" in menu_text:
		failures.append("menu-mockup-master-reference-present")
	if "RightPortal" not in menu_text:
		failures.append("menu-right-portal-missing")
	if "WorldJourneyTrace" not in menu_text:
		failures.append("menu-independent-journey-trace-missing")
	if "res://assets/branding/JOSESI.png" not in wordmark_text:
		failures.append("immutable-josesi-wordmark-not-used")
	if "logo_dkv_unpari_official" in wordmark_text or "josesi_wordmark_letters" in wordmark_text:
		failures.append("legacy-wordmark-reconstruction-reference-present")

	if failures.is_empty():
		print("JOSESI_01_BUNDLE_CONTRACT=PASS")
		quit(0)
		return

	print("JOSESI_01_BUNDLE_CONTRACT=FAIL")
	for failure in failures:
		print("BUNDLE_CONTRACT_FAILURE=" + failure)
	quit(2)
