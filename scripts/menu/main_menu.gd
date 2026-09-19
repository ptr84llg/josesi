extends Control

signal request_continue
signal request_new_journey
signal request_open_portfolio
signal request_open_settings
signal request_open_about
signal request_exit
signal resume_target_resolved(scene_path: String, spawn_id: String)
signal new_journey_created
signal save_load_failed(message: String)
signal portfolio_unread_cleared

const SettingsStore := preload("res://scripts/systems/settings_store.gd")
const SaveProgressAdapter := preload("res://scripts/systems/save_progress_adapter.gd")

@export_file("*.tscn") var journey_start_scene := ""
@export var journey_start_spawn := "journey_entry"
@export var journey_start_destination_label := "Main Journey Hub"

@onready var primary_cta: Button = $SafeArea/NavigationColumn/PrimaryCTA
@onready var new_journey_button: Button = $SafeArea/NavigationColumn/NewJourneyButton
@onready var portfolio_button: Button = $SafeArea/NavigationColumn/PortfolioButton
@onready var settings_button: Button = $SafeArea/NavigationColumn/SettingsButton
@onready var about_button: Button = $SafeArea/NavigationColumn/AboutButton
@onready var exit_button: Button = $SafeArea/NavigationColumn/ExitButton
@onready var current_journey_panel: PanelContainer = $CurrentJourneyPanel
@onready var current_stage_label: Label = $CurrentJourneyPanel/PanelMargin/PanelHBox/JourneyInfo/CurrentStageLabel
@onready var portfolio_status_label: Label = $CurrentJourneyPanel/PanelMargin/PanelHBox/JourneyInfo/PortfolioStatusLabel
@onready var destination_label: Label = $CurrentJourneyPanel/PanelMargin/PanelHBox/DestinationInfo/DestinationLabel
@onready var stage_progress: Control = $CurrentJourneyPanel/PanelMargin/PanelHBox/StageProgress
@onready var portfolio_unread_dot: Label = $SafeArea/NavigationColumn/PortfolioButton/UnreadDot
@onready var settings_overlay: Control = $OverlayLayer/SettingsOverlay
@onready var reduce_motion_toggle: CheckButton = $OverlayLayer/SettingsOverlay/Panel/PanelMargin/Content/ReduceMotionToggle
@onready var settings_close_button: Button = $OverlayLayer/SettingsOverlay/Panel/PanelMargin/Content/CloseButton
@onready var about_overlay: Control = $OverlayLayer/AboutOverlay
@onready var about_close_button: Button = $OverlayLayer/AboutOverlay/Panel/PanelMargin/Content/CloseButton
@onready var confirmation_modal: Control = $OverlayLayer/ConfirmationModal
@onready var confirmation_title: Label = $OverlayLayer/ConfirmationModal/Panel/PanelMargin/Content/TitleLabel
@onready var confirmation_body: Label = $OverlayLayer/ConfirmationModal/Panel/PanelMargin/Content/BodyLabel
@onready var confirmation_cancel: Button = $OverlayLayer/ConfirmationModal/Panel/PanelMargin/Content/Buttons/CancelButton
@onready var confirmation_accept: Button = $OverlayLayer/ConfirmationModal/Panel/PanelMargin/Content/Buttons/AcceptButton
@onready var info_modal: Control = $OverlayLayer/InfoModal
@onready var info_title: Label = $OverlayLayer/InfoModal/Panel/PanelMargin/Content/TitleLabel
@onready var info_body: Label = $OverlayLayer/InfoModal/Panel/PanelMargin/Content/BodyLabel
@onready var info_close: Button = $OverlayLayer/InfoModal/Panel/PanelMargin/Content/CloseButton

var _model: Dictionary = {}
var _state := "FIRST_LAUNCH"
var _reduce_motion := false
var _confirmation_action := ""
var _return_focus: Control

func _ready() -> void:
	_reduce_motion = SettingsStore.load_reduce_motion()
	_connect_controls()
	_hide_all_overlays()
	_refresh_from_save()
	print("JOSESI_MAIN_MENU_READY=TRUE state=%s" % _state)
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.12 if _reduce_motion else 0.55)
	primary_cta.grab_focus.call_deferred()

func _connect_controls() -> void:
	primary_cta.pressed.connect(_on_primary_pressed)
	new_journey_button.pressed.connect(_on_new_journey_pressed)
	portfolio_button.pressed.connect(_on_portfolio_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	about_button.pressed.connect(_on_about_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	settings_close_button.pressed.connect(_close_settings)
	about_close_button.pressed.connect(_close_about)
	reduce_motion_toggle.toggled.connect(_on_reduce_motion_toggled)
	confirmation_cancel.pressed.connect(_close_confirmation)
	confirmation_accept.pressed.connect(_accept_confirmation)
	info_close.pressed.connect(_close_info_modal)

func _refresh_from_save() -> void:
	_model = SaveProgressAdapter.load_view_model()
	_state = _resolve_menu_state(_model)
	_apply_state()

func _resolve_menu_state(model: Dictionary) -> String:
	if bool(model.get("save_load_error", false)):
		return "SAVE_LOAD_ERROR"
	if not bool(model.get("has_valid_save", false)):
		return "FIRST_LAUNCH"
	if bool(model.get("journey_complete", false)):
		return "COMPLETED_JOURNEY"
	return "RETURNING_PLAYER"

func _apply_state() -> void:
	var has_save := bool(_model.get("has_valid_save", false))
	var portfolio_count := int(_model.get("portfolio_count", 0))
	portfolio_unread_dot.visible = bool(_model.get("portfolio_unread", false)) and portfolio_count >= 1

	match _state:
		"FIRST_LAUNCH":
			primary_cta.text = "MULAI PERJALANAN"
			new_journey_button.visible = false
			portfolio_button.visible = false
			current_journey_panel.visible = false
		"RETURNING_PLAYER":
			primary_cta.text = "LANJUTKAN PERJALANAN"
			new_journey_button.visible = true
			portfolio_button.visible = portfolio_count >= 1
			current_journey_panel.visible = true
			_render_current_journey()
		"COMPLETED_JOURNEY":
			primary_cta.text = "LANJUTKAN PERJALANAN"
			new_journey_button.visible = true
			portfolio_button.visible = true
			current_journey_panel.visible = true
			_render_current_journey()
		"SAVE_LOAD_ERROR":
			primary_cta.text = "PEMULIHAN DATA"
			new_journey_button.visible = false
			portfolio_button.visible = false
			current_journey_panel.visible = true
			current_stage_label.text = "DATA PERJALANAN TIDAK DAPAT DIBACA"
			portfolio_status_label.text = "Progress tidak direka atau ditebak."
			destination_label.text = "Buka pemulihan untuk informasi lebih lanjut."
			stage_progress.set_stage_states({"SEE":"LOCKED", "EXPLORE":"LOCKED", "SOLVE":"LOCKED", "INTEGRATE":"LOCKED"})

	if not has_save and _state != "SAVE_LOAD_ERROR":
		current_journey_panel.visible = false
	_update_focus_navigation()

func _render_current_journey() -> void:
	var stage = _model.get("current_stage", null)
	var area = _model.get("current_area", null)
	var destination = _model.get("destination_label", null)
	var portfolio_count := int(_model.get("portfolio_count", 0))
	current_stage_label.text = "%s — %s" % ["PERJALANAN SELESAI" if stage == null else str(stage), "" if area == null else str(area)]
	portfolio_status_label.text = "Portofolio %d / 4" % portfolio_count
	destination_label.text = "Lanjutkan menuju\n%s" % ("Perjalanan berikutnya" if destination == null else str(destination))
	stage_progress.set_stage_states(_model.get("stage_states", {}))

func _update_focus_navigation() -> void:
	var visible_buttons: Array[Button] = []
	for button in [primary_cta, new_journey_button, portfolio_button, settings_button, about_button, exit_button]:
		if button.visible and not button.disabled:
			visible_buttons.append(button)
	if visible_buttons.is_empty():
		return
	for i in range(visible_buttons.size()):
		var button := visible_buttons[i]
		var previous := visible_buttons[(i - 1 + visible_buttons.size()) % visible_buttons.size()]
		var next := visible_buttons[(i + 1) % visible_buttons.size()]
		button.focus_neighbor_top = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_next = button.get_path_to(next)
		button.focus_previous = button.get_path_to(previous)

func _on_primary_pressed() -> void:
	if _state == "FIRST_LAUNCH":
		request_new_journey.emit()
		_start_new_journey_if_available()
		return
	if _state == "SAVE_LOAD_ERROR":
		_show_info("PEMULIHAN DATA", "Data perjalanan terdeteksi tetapi tidak dapat dibaca. JOSESI tidak akan membuat target Continue palsu. Pemulihan save akan diintegrasikan bersama sistem progression.", primary_cta)
		save_load_failed.emit("SAVE_LOAD_ERROR")
		return
	request_continue.emit()
	_resume_authoritative_target()

func _on_new_journey_pressed() -> void:
	request_new_journey.emit()
	_confirmation_action = "NEW_JOURNEY"
	_show_confirmation(
		"Mulai perjalanan baru?",
		"Progress perjalanan saat ini akan diganti dengan perjalanan baru.",
		"MULAI PERJALANAN BARU",
		new_journey_button
	)

func _on_portfolio_pressed() -> void:
	request_open_portfolio.emit()
	if int(_model.get("portfolio_count", 0)) < 1:
		return
	var clear_err := SaveProgressAdapter.mark_portfolio_read()
	if clear_err == OK:
		portfolio_unread_dot.visible = false
		portfolio_unread_cleared.emit()
	_show_info("PORTOFOLIO", "Tombol Portofolio sudah mengikuti progression. Scene Portofolio belum termasuk scope Splash Loader + Main Menu JOSESI 01.", portfolio_button)

func _on_settings_pressed() -> void:
	request_open_settings.emit()
	_return_focus = settings_button
	reduce_motion_toggle.button_pressed = SettingsStore.load_reduce_motion()
	settings_overlay.visible = true
	settings_overlay.move_to_front()
	reduce_motion_toggle.grab_focus.call_deferred()

func _on_about_pressed() -> void:
	request_open_about.emit()
	_return_focus = about_button
	about_overlay.visible = true
	about_overlay.move_to_front()
	about_close_button.grab_focus.call_deferred()

func _on_exit_pressed() -> void:
	request_exit.emit()
	_confirmation_action = "EXIT"
	_show_confirmation("Keluar dari JOSESI?", "", "KELUAR", exit_button)

func _on_reduce_motion_toggled(enabled: bool) -> void:
	var err := SettingsStore.save_reduce_motion(enabled)
	if err == OK:
		_reduce_motion = enabled
	else:
		_show_info("PENGATURAN", "Pengaturan Kurangi Gerakan tidak dapat disimpan: %s" % error_string(err), settings_button)

func _close_settings() -> void:
	settings_overlay.visible = false
	_restore_focus()

func _close_about() -> void:
	about_overlay.visible = false
	_restore_focus()

func _show_confirmation(title: String, body: String, accept_text: String, return_focus: Control) -> void:
	_return_focus = return_focus
	confirmation_title.text = title
	confirmation_body.text = body
	confirmation_accept.text = accept_text
	confirmation_modal.visible = true
	confirmation_modal.move_to_front()
	confirmation_cancel.grab_focus.call_deferred()

func _close_confirmation() -> void:
	confirmation_modal.visible = false
	_confirmation_action = ""
	_restore_focus()

func _accept_confirmation() -> void:
	var action := _confirmation_action
	confirmation_modal.visible = false
	_confirmation_action = ""
	match action:
		"NEW_JOURNEY":
			_start_new_journey_if_available()
		"EXIT":
			get_tree().quit()
		_:
			_restore_focus()

func _start_new_journey_if_available() -> void:
	if journey_start_scene.is_empty() or not ResourceLoader.exists(journey_start_scene):
		_show_info(
			"PERJALANAN BELUM TERHUBUNG",
			"Splash Loader dan Main Menu sudah berada pada tahap implementasi. Main Journey Hub tidak termasuk scope JOSESI 01 ini, sehingga progress belum dibuat sebelum target perjalanan yang authoritative tersedia.",
			primary_cta
		)
		return
	var result := SaveProgressAdapter.create_new_journey(journey_start_scene, journey_start_spawn, journey_start_destination_label)
	if not bool(result.get("ok", false)):
		_show_info("PERJALANAN TIDAK DAPAT DIMULAI", str(result.get("error", "Unknown error")), primary_cta)
		return
	new_journey_created.emit()
	_transition_to_scene(journey_start_scene, journey_start_spawn)

func _resume_authoritative_target() -> void:
	var raw_scene = _model.get("resume_scene", null)
	var raw_spawn = _model.get("resume_spawn", null)
	var scene_path := "" if raw_scene == null else str(raw_scene)
	var spawn_id := "" if raw_spawn == null else str(raw_spawn)
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_show_info("TARGET PERJALANAN TIDAK VALID", "Save tidak menyediakan target scene yang valid. JOSESI tidak akan menebak level atau zona tujuan.", primary_cta)
		save_load_failed.emit("INVALID_RESUME_TARGET")
		return
	resume_target_resolved.emit(scene_path, spawn_id)
	_transition_to_scene(scene_path, spawn_id)

func _transition_to_scene(scene_path: String, spawn_id: String) -> void:
	set_meta("requested_spawn_id", spawn_id)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_show_info("TRANSISI GAGAL", "Scene tujuan tidak dapat dimuat.", primary_cta)
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.10 if _reduce_motion else 0.42)
	await tween.finished
	get_tree().change_scene_to_packed(packed)

func _show_info(title: String, body: String, return_focus: Control) -> void:
	_return_focus = return_focus
	info_title.text = title
	info_body.text = body
	info_modal.visible = true
	info_modal.move_to_front()
	info_close.grab_focus.call_deferred()

func _close_info_modal() -> void:
	info_modal.visible = false
	_restore_focus()

func _restore_focus() -> void:
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.visible:
		_return_focus.grab_focus.call_deferred()
	else:
		primary_cta.grab_focus.call_deferred()

func _hide_all_overlays() -> void:
	settings_overlay.visible = false
	about_overlay.visible = false
	confirmation_modal.visible = false
	info_modal.visible = false
