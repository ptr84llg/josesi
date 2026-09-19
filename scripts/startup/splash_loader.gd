extends Control

signal splash_reveal_finished
signal loading_progress_changed(actual_progress: float, displayed_progress: float)
signal loading_ready
signal loading_warning(message: String)
signal loading_error(message: String)
signal retry_requested
signal exit_requested
signal transition_to_main_menu_started
signal transition_to_main_menu_finished

const MAIN_MENU_PATH := "res://scenes/menu/main_menu.tscn"
const SettingsStore := preload("res://scripts/systems/settings_store.gd")
const SaveProgressAdapter := preload("res://scripts/systems/save_progress_adapter.gd")

@onready var identity_layer: Control = $IdentityLayer
@onready var loader_layer: Control = $LoaderLayer
@onready var loading_title: Label = $LoaderLayer/LoadingTitle
@onready var loading_status: Label = $LoaderLayer/LoadingStatus
@onready var trace_loader: Control = $LoaderLayer/TraceLoader
@onready var percentage_label: Label = $LoaderLayer/PercentageLabel
@onready var overlay_layer: Control = $OverlayLayer
@onready var warning_error_panel: PanelContainer = $OverlayLayer/WarningErrorPanel
@onready var overlay_title: Label = $OverlayLayer/WarningErrorPanel/PanelMargin/PanelVBox/TitleLabel
@onready var overlay_message: Label = $OverlayLayer/WarningErrorPanel/PanelMargin/PanelVBox/MessageLabel
@onready var retry_button: Button = $OverlayLayer/WarningErrorPanel/PanelMargin/PanelVBox/Buttons/RetryButton
@onready var exit_button: Button = $OverlayLayer/WarningErrorPanel/PanelMargin/PanelVBox/Buttons/ExitButton
@onready var footer_build: Label = $FooterLayer/BuildLabel
@onready var transition_cover: ColorRect = $TransitionCover

var _state := "SPLASH_REVEAL"
var _actual_progress := 0.0
var _displayed_progress := 0.0
var _main_menu_resource: PackedScene
var _reduce_motion := false
var _run_token := 0
var _warning_detected := false

func _ready() -> void:
	_reduce_motion = SettingsStore.load_reduce_motion()
	footer_build.text = "JOSESI v%s  •  DEVELOPMENT BUILD" % str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	retry_button.pressed.connect(_on_retry_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	transition_cover.modulate.a = 0.0
	_set_state("SPLASH_REVEAL")
	call_deferred("_run_loader")

func _process(delta: float) -> void:
	if _displayed_progress < _actual_progress:
		_displayed_progress = minf(_actual_progress, move_toward(_displayed_progress, _actual_progress, delta * 1.65))
		_update_progress_ui()

func _run_loader() -> void:
	_run_token += 1
	var token := _run_token
	_warning_detected = false
	_main_menu_resource = null
	_actual_progress = 0.0
	_displayed_progress = 0.0
	_update_progress_ui()
	warning_error_panel.visible = false
	overlay_layer.visible = false
	identity_layer.modulate.a = 0.0
	loader_layer.visible = false
	loader_layer.modulate.a = 1.0
	transition_cover.modulate.a = 0.0
	_set_state("SPLASH_REVEAL")

	await _play_identity_reveal()
	if token != _run_token:
		return
	splash_reveal_finished.emit()
	_set_state("LOADING")
	loader_layer.visible = true
	loader_layer.modulate.a = 0.0
	var loader_tween := create_tween()
	loader_tween.tween_property(loader_layer, "modulate:a", 1.0, 0.12 if _reduce_motion else 0.30)

	var preload_ok := await _run_preload_phases(token)
	if not preload_ok:
		return
	if token != _run_token:
		return

	_actual_progress = 1.0
	while _displayed_progress < 0.999 and token == _run_token:
		await get_tree().process_frame
	if token != _run_token:
		return

	_set_state("READY")
	loading_title.text = "PERJALANAN SIAP"
	loading_status.text = "Membuka Journey Portal..."
	percentage_label.text = "100%"
	loading_ready.emit()
	await get_tree().create_timer(0.15 if _reduce_motion else 0.32).timeout
	if token != _run_token:
		return
	await _transition_to_main_menu(token)

func _play_identity_reveal() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(identity_layer, "modulate:a", 1.0, 0.12 if _reduce_motion else 0.48)
	await tween.finished

func _run_preload_phases(token: int) -> bool:
	if not _complete_phase(token, 0.10, "Menyiapkan konfigurasi inti..."):
		return false
	await get_tree().process_frame

	_reduce_motion = SettingsStore.load_reduce_motion()
	if not _complete_phase(token, 0.20, "Menyiapkan input dan pengaturan..."):
		return false
	await get_tree().process_frame

	var returning_player := FileAccess.file_exists(SaveProgressAdapter.SAVE_PATH)
	var save_model := SaveProgressAdapter.load_view_model()
	if bool(save_model.get("save_load_error", false)):
		_warning_detected = true
		_set_state("LOAD_WARNING")
		loading_status.text = "Data perjalanan perlu dipulihkan di menu..."
		loading_warning.emit("Data perjalanan terdeteksi tetapi tidak dapat dibaca.")
	else:
		_set_state("LOADING")
		loading_status.text = "Membaca data perjalanan..." if returning_player else "Menyiapkan perjalanan baru..."
	if not _complete_phase(token, 0.35, loading_status.text):
		return false
	await get_tree().process_frame

	if not ResourceLoader.exists("res://assets/branding/logo_dkv_unpari_official.png"):
		_show_load_error("Logo resmi DKV UNPARI tidak ditemukan.")
		return false
	if not ResourceLoader.exists("res://assets/menu/world_panorama_concept_reference.png"):
		_show_load_error("Reference panorama Main Menu tidak ditemukan.")
		return false
	if not _complete_phase(token, 0.50, "Menyiapkan antarmuka..."):
		return false
	await get_tree().process_frame

	# No audio asset is introduced in JOSESI 01. This phase verifies the runtime audio service only.
	if AudioServer.bus_count <= 0:
		_show_load_error("Layanan audio Godot tidak tersedia.")
		return false
	if not _complete_phase(token, 0.60, "Menyiapkan audio..."):
		return false
	await get_tree().process_frame

	loading_status.text = "Menyiapkan lingkungan..."
	var request_err := ResourceLoader.load_threaded_request(MAIN_MENU_PATH)
	if request_err != OK:
		_show_load_error("Main Menu gagal diminta untuk dimuat: %s" % error_string(request_err))
		return false

	while token == _run_token:
		var progress_array: Array = []
		var threaded_status := ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH, progress_array)
		match threaded_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var threaded_ratio := 0.0
				if not progress_array.is_empty():
					threaded_ratio = clampf(float(progress_array[0]), 0.0, 1.0)
				_set_actual_progress(0.60 + threaded_ratio * 0.25)
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				var loaded := ResourceLoader.load_threaded_get(MAIN_MENU_PATH)
				if not (loaded is PackedScene):
					_show_load_error("Resource Main Menu bukan PackedScene yang valid.")
					return false
				_main_menu_resource = loaded as PackedScene
				_set_actual_progress(0.85)
				break
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_show_load_error("Main Menu gagal dimuat.")
				return false
			_:
				_show_load_error("Status loader Main Menu tidak dikenal.")
				return false
	if token != _run_token:
		return false

	loading_status.text = "Hampir siap..."
	if _main_menu_resource == null or not _main_menu_resource.can_instantiate():
		_show_load_error("Main Menu tidak dapat diinstansiasi.")
		return false
	_set_actual_progress(1.0)
	return true

func _complete_phase(token: int, target_progress: float, status_text: String) -> bool:
	if token != _run_token:
		return false
	loading_title.text = "MENYIAPKAN PERJALANAN"
	loading_status.text = status_text
	_set_actual_progress(target_progress)
	return true

func _set_actual_progress(value: float) -> void:
	_actual_progress = clampf(value, 0.0, 1.0)
	if _displayed_progress > _actual_progress:
		_displayed_progress = _actual_progress
	_update_progress_ui()

func _update_progress_ui() -> void:
	trace_loader.set_progress(_displayed_progress)
	percentage_label.text = "%d%%" % int(round(_displayed_progress * 100.0))
	loading_progress_changed.emit(_actual_progress, _displayed_progress)

func _set_state(new_state: String) -> void:
	_state = new_state
	match _state:
		"SPLASH_REVEAL":
			loading_title.visible = false
			loading_status.visible = false
			trace_loader.visible = false
			percentage_label.visible = false
		"LOADING", "LOAD_WARNING":
			loading_title.visible = true
			loading_status.visible = true
			trace_loader.visible = true
			percentage_label.visible = true
		"READY":
			loading_title.visible = true
			loading_status.visible = true
			trace_loader.visible = true
			percentage_label.visible = true
		"LOAD_ERROR":
			loading_title.visible = true
			loading_status.visible = true
			trace_loader.visible = true
			percentage_label.visible = false
		"TRANSITION_TO_MENU":
			pass

func _show_load_error(message: String) -> void:
	_set_state("LOAD_ERROR")
	loading_status.text = "Pemuatan tidak dapat diselesaikan."
	overlay_layer.visible = true
	warning_error_panel.visible = true
	overlay_title.text = "PEMUATAN TERHENTI"
	overlay_message.text = message
	retry_button.visible = true
	exit_button.visible = true
	retry_button.grab_focus.call_deferred()
	loading_error.emit(message)

func _on_retry_pressed() -> void:
	retry_requested.emit()
	call_deferred("_run_loader")

func _on_exit_pressed() -> void:
	exit_requested.emit()
	get_tree().quit()

func _transition_to_main_menu(token: int) -> void:
	if _main_menu_resource == null:
		_show_load_error("Main Menu belum tersedia untuk transisi.")
		return
	_set_state("TRANSITION_TO_MENU")
	transition_to_main_menu_started.emit()
	trace_loader.set_transition_mode(true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(identity_layer, "modulate:a", 0.0, 0.12 if _reduce_motion else 0.55)
	tween.tween_property(loader_layer, "modulate:a", 0.0, 0.12 if _reduce_motion else 0.55)
	tween.tween_property(transition_cover, "modulate:a", 1.0, 0.12 if _reduce_motion else 0.55)
	await tween.finished
	if token != _run_token:
		return
	transition_to_main_menu_finished.emit()
	get_tree().change_scene_to_packed(_main_menu_resource)
