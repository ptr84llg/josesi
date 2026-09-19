extends Control

const SaveProgressAdapter = preload("res://scripts/systems/save_progress_adapter.gd")
@export var current_stage_texture: Texture2D
@export var complete_stage_texture: Texture2D

const STATE_FIRST_LAUNCH := "FIRST_LAUNCH"
const STATE_RETURNING_PLAYER := "RETURNING_PLAYER"
const STATE_COMPLETED_JOURNEY := "COMPLETED_JOURNEY"
const STATE_SAVE_LOAD_ERROR := "SAVE_LOAD_ERROR"

@onready var title_label: Label = $SafeArea/RightPortal/BrandBlock/SubtitleLabel
@onready var primary_button: JosesiActionButton = $SafeArea/RightPortal/MenuStack/PrimaryButton
@onready var new_journey_button: JosesiActionButton = $SafeArea/RightPortal/MenuStack/NewJourneyButton
@onready var portfolio_button: JosesiActionButton = $SafeArea/RightPortal/MenuStack/PortfolioButton
@onready var settings_button: JosesiActionButton = $SafeArea/RightPortal/MenuStack/SettingsButton
@onready var about_button: JosesiActionButton = $SafeArea/RightPortal/MenuStack/AboutButton
@onready var exit_button: JosesiActionButton = $SafeArea/RightPortal/MenuStack/ExitButton
@onready var footer_label: Label = $Footer/BuildLabel
@onready var journey_panel: Control = $SafeArea/JourneyDock
@onready var journey_stage_icon: TextureRect = $SafeArea/JourneyDock/StageIcon
@onready var journey_title: Label = $SafeArea/JourneyDock/Title
@onready var journey_portfolio: Label = $SafeArea/JourneyDock/Portfolio
@onready var journey_destination: Label = $SafeArea/JourneyDock/Destination
@onready var stage_indicator: Control = $SafeArea/JourneyDock/StageProgress
@onready var modal_overlay: ColorRect = $ModalLayer/ModalOverlay
@onready var modal_panel: Control = $ModalLayer/ModalPanel
@onready var modal_title: Label = $ModalLayer/ModalPanel/Title
@onready var modal_body: RichTextLabel = $ModalLayer/ModalPanel/Body
@onready var modal_confirm: JosesiActionButton = $ModalLayer/ModalPanel/ButtonRow/ConfirmButton
@onready var modal_cancel: JosesiActionButton = $ModalLayer/ModalPanel/ButtonRow/CancelButton

var _state_name: String = STATE_FIRST_LAUNCH
var _deferred_action: Callable

func _ready() -> void:
	modal_overlay.visible = false
	modal_panel.visible = false
	footer_label.text = "Development Build  |  JOSESI  |  © 2026"
	_wire_buttons()
	_apply_view_model(_build_menu_view_model())
	await get_tree().process_frame
	print("JOSESI_MAIN_MENU_READY=TRUE state=%s" % _state_name)

func get_menu_state_name() -> String:
	return _state_name

func _wire_buttons() -> void:
	primary_button.pressed.connect(_on_primary_pressed)
	new_journey_button.pressed.connect(_on_new_journey_pressed)
	portfolio_button.pressed.connect(_on_portfolio_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	about_button.pressed.connect(_on_about_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	modal_confirm.pressed.connect(_on_modal_confirmed)
	modal_cancel.pressed.connect(_close_modal)

func _build_menu_view_model() -> Dictionary:
	var model: Dictionary = SaveProgressAdapter.load_view_model()
	var state := STATE_FIRST_LAUNCH
	if bool(model.get("save_load_error", false)):
		state = STATE_SAVE_LOAD_ERROR
	elif bool(model.get("journey_complete", false)):
		state = STATE_COMPLETED_JOURNEY
	elif bool(model.get("has_valid_save", false)):
		state = STATE_RETURNING_PLAYER

	var current_stage_value = model.get("current_stage", null)
	var destination_value = model.get("destination_label", null)
	return {
		"state": state,
		"portfolio_count": int(model.get("portfolio_count", 0)),
		"portfolio_unread": bool(model.get("portfolio_unread", false)),
		"current_stage": "SEE" if current_stage_value == null else str(current_stage_value),
		"resume_target": "Visual Orientation" if destination_value == null else str(destination_value),
		"stage_states": model.get("stage_states", {}),
	}

func _apply_view_model(view_model: Dictionary) -> void:
	_state_name = str(view_model.get("state", STATE_FIRST_LAUNCH))
	var portfolio_count: int = clampi(int(view_model.get("portfolio_count", 0)), 0, 4)
	var current_stage := str(view_model.get("current_stage", "SEE"))
	var resume_target := str(view_model.get("resume_target", "Visual Orientation"))
	var stage_states: Dictionary = view_model.get("stage_states", {})
	if stage_states.is_empty():
		stage_states = {
			"SEE": "AVAILABLE",
			"EXPLORE": "LOCKED",
			"SOLVE": "LOCKED",
			"INTEGRATE": "LOCKED",
		}

	portfolio_button.notification_visible = bool(view_model.get("portfolio_unread", false))

	match _state_name:
		STATE_FIRST_LAUNCH:
			title_label.text = "Melangkah. Mengalami. Merancang Masa Depan."
			primary_button.text = "MULAI PERJALANAN"
			new_journey_button.visible = false
			portfolio_button.visible = false
			journey_panel.visible = false
		STATE_RETURNING_PLAYER:
			title_label.text = "Melangkah. Mengalami. Merancang Masa Depan."
			primary_button.text = "LANJUTKAN PERJALANAN"
			new_journey_button.visible = true
			portfolio_button.visible = true
			journey_panel.visible = true
			journey_stage_icon.texture = current_stage_texture
			journey_title.text = "%s — Communication Path" % current_stage
			journey_portfolio.text = "Portofolio %d / 4" % portfolio_count
			journey_destination.text = "Lanjutkan menuju\n%s" % resume_target
		STATE_COMPLETED_JOURNEY:
			title_label.text = "Perjalanan utama selesai. Tinjau kembali artefak dan identitas desainmu."
			primary_button.text = "LIHAT PERJALANAN"
			new_journey_button.visible = true
			portfolio_button.visible = true
			journey_panel.visible = true
			journey_stage_icon.texture = complete_stage_texture
			journey_title.text = "INTEGRATE — Final Journey"
			journey_portfolio.text = "Portofolio 4 / 4"
			journey_destination.text = "Perjalanan selesai\nJourney Showcase"
			stage_states = {"SEE":"COMPLETE", "EXPLORE":"COMPLETE", "SOLVE":"COMPLETE", "INTEGRATE":"CURRENT"}
		STATE_SAVE_LOAD_ERROR:
			title_label.text = "Data perjalanan tidak dapat dibaca."
			primary_button.text = "MULAI ULANG"
			new_journey_button.visible = false
			portfolio_button.visible = false
			journey_panel.visible = false
		_:
			_state_name = STATE_FIRST_LAUNCH
			_apply_view_model({})
			return

	stage_indicator.call("set_stage_states", stage_states)

func _on_primary_pressed() -> void:
	match _state_name:
		STATE_FIRST_LAUNCH:
			_show_modal("Mulai Perjalanan", "Main Journey Hub belum dihubungkan pada tahap JOSESI 01. Visual Splash Loader dan Main Menu sudah berdiri sebagai baseline navigasi.", Callable())
		STATE_RETURNING_PLAYER:
			_show_modal("Lanjutkan Perjalanan", "Resume target akan diarahkan ke Main Journey Hub pada tahap implementasi berikutnya.", Callable())
		STATE_COMPLETED_JOURNEY:
			_show_modal("Perjalanan Selesai", "Journey Showcase akan dihubungkan setelah Main Journey Hub dan galeri akhir tersedia.", Callable())
		STATE_SAVE_LOAD_ERROR:
			_show_modal("Mulai Ulang", "Data perjalanan tidak dapat dibaca. Perjalanan baru akan tersedia ketika Main Journey Hub sudah terhubung.", Callable())

func _on_new_journey_pressed() -> void:
	_show_modal("Perjalanan Baru", "Memulai ulang perjalanan akan diaktifkan setelah target Main Journey Hub tersedia.", Callable())

func _on_portfolio_pressed() -> void:
	_show_modal("Portofolio", "Panel portofolio penuh akan dihubungkan setelah artefak Level 1–4 tersedia.", Callable())

func _on_settings_pressed() -> void:
	_show_modal("Pengaturan", "Pengaturan audio dan preferensi permainan akan dihubungkan pada tahap sistem berikutnya.", Callable())

func _on_about_pressed() -> void:
	_show_modal("Tentang JOSESI", "JOSESI merepresentasikan perjalanan studi mahasiswa DKV melalui SEE → EXPLORE → SOLVE → INTEGRATE.", Callable())

func _on_exit_pressed() -> void:
	_show_modal("Keluar", "Tutup aplikasi JOSESI sekarang?", func() -> void:
		get_tree().quit()
	)

func _show_modal(title: String, body: String, action: Callable) -> void:
	modal_title.text = title
	modal_body.text = body
	_deferred_action = action
	modal_overlay.visible = true
	modal_panel.visible = true
	modal_confirm.focus_button()

func _close_modal() -> void:
	modal_overlay.visible = false
	modal_panel.visible = false
	_deferred_action = Callable()
	primary_button.focus_button()

func _on_modal_confirmed() -> void:
	var action := _deferred_action
	_close_modal()
	if action.is_valid():
		action.call()
