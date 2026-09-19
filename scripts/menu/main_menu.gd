extends Control

const STATE_FIRST_LAUNCH := "FIRST_LAUNCH"
const STATE_RETURNING_PLAYER := "RETURNING_PLAYER"
const STATE_COMPLETED_JOURNEY := "COMPLETED_JOURNEY"
const STATE_SAVE_LOAD_ERROR := "SAVE_LOAD_ERROR"

@onready var title_label: Label = $SafeArea/LeftColumn/BrandBlock/SubtitleLabel
@onready var primary_button: Button = $SafeArea/LeftColumn/MenuBlock/PrimaryButton
@onready var new_journey_button: Button = $SafeArea/LeftColumn/MenuBlock/NewJourneyButton
@onready var portfolio_button: Button = $SafeArea/LeftColumn/MenuBlock/PortfolioButton
@onready var settings_button: Button = $SafeArea/LeftColumn/MenuBlock/SettingsButton
@onready var about_button: Button = $SafeArea/LeftColumn/MenuBlock/AboutButton
@onready var exit_button: Button = $SafeArea/LeftColumn/MenuBlock/ExitButton
@onready var footer_label: Label = $Footer/BuildLabel
@onready var stage_indicator: Control = $SafeArea/BottomDock/JourneyPanel/HBox/StageProgress
@onready var journey_panel: PanelContainer = $SafeArea/BottomDock/JourneyPanel
@onready var journey_title: Label = $SafeArea/BottomDock/JourneyPanel/HBox/JourneyInfo/VBox/Title
@onready var journey_subtitle: Label = $SafeArea/BottomDock/JourneyPanel/HBox/JourneyInfo/VBox/SubTitle
@onready var modal_overlay: ColorRect = $ModalLayer/ModalOverlay
@onready var modal_panel: PanelContainer = $ModalLayer/ModalPanel
@onready var modal_title: Label = $ModalLayer/ModalPanel/VBox/Title
@onready var modal_body: RichTextLabel = $ModalLayer/ModalPanel/VBox/Body
@onready var modal_confirm: Button = $ModalLayer/ModalPanel/VBox/ButtonRow/ConfirmButton
@onready var modal_cancel: Button = $ModalLayer/ModalPanel/VBox/ButtonRow/CancelButton
@onready var current_journey_badge: Label = $SafeArea/BottomDock/JourneyPanel/HBox/Badge

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
	var view_model := {
		"state": STATE_FIRST_LAUNCH,
		"portfolio_count": 0,
		"current_stage": "SEE",
		"resume_target": "Visual Orientation",
		"journey_started": false,
		"journey_completed": false,
	}

	if ResourceLoader.exists("res://scripts/systems/save_progress_adapter.gd"):
		var adapter_script := load("res://scripts/systems/save_progress_adapter.gd")
		if adapter_script != null:
			var adapter = adapter_script.new()
			for method_name in ["build_menu_view_model", "get_menu_view_model", "build_main_menu_view_model"]:
				if adapter.has_method(method_name):
					var result = adapter.call(method_name)
					if typeof(result) == TYPE_DICTIONARY and not result.is_empty():
						view_model.merge(result, true)
						break

	return view_model

func _apply_view_model(view_model: Dictionary) -> void:
	_state_name = str(view_model.get("state", STATE_FIRST_LAUNCH))
	var portfolio_count := int(view_model.get("portfolio_count", 0))
	var current_stage := str(view_model.get("current_stage", "SEE"))
	var resume_target := str(view_model.get("resume_target", "Visual Orientation"))

	var stage_states := {
		"SEE": "AVAILABLE",
		"EXPLORE": "LOCKED",
		"SOLVE": "LOCKED",
		"INTEGRATE": "LOCKED",
	}

	match _state_name:
		STATE_FIRST_LAUNCH:
			title_label.text = "Melangkah. Mengalami. Merancang Masa Depan."
			primary_button.text = "MULAI PERJALANAN"
			new_journey_button.visible = false
			portfolio_button.visible = false
			journey_panel.visible = false
			stage_states["SEE"] = "AVAILABLE"
		STATE_RETURNING_PLAYER:
			title_label.text = "Kembali ke Journey Portal dan lanjutkan langkah kreatifmu."
			primary_button.text = "LANJUTKAN PERJALANAN"
			new_journey_button.visible = true
			portfolio_button.visible = true
			journey_panel.visible = true
			_apply_returning_stage_states(stage_states, current_stage)
			journey_title.text = "%s — Journey Path" % current_stage
			journey_subtitle.text = "Lanjutkan menuju %s\nPortofolio %d / 4" % [resume_target, clamp(portfolio_count, 0, 4)]
			current_journey_badge.text = str(clamp(portfolio_count, 0, 4)) + "/4"
		STATE_COMPLETED_JOURNEY:
			title_label.text = "Perjalanan utama selesai. Tinjau kembali artefak dan identitas desainmu."
			primary_button.text = "LIHAT PERJALANAN"
			new_journey_button.visible = true
			portfolio_button.visible = true
			journey_panel.visible = true
			stage_states = {"SEE":"COMPLETE", "EXPLORE":"COMPLETE", "SOLVE":"COMPLETE", "INTEGRATE":"CURRENT"}
			journey_title.text = "INTEGRATE — Final Journey"
			journey_subtitle.text = "Perjalanan selesai\nPortofolio 4 / 4"
			current_journey_badge.text = "4/4"
		STATE_SAVE_LOAD_ERROR:
			title_label.text = "Data perjalanan tidak dapat dibaca. Silakan mulai ulang atau periksa penyimpanan."
			primary_button.text = "MULAI ULANG"
			new_journey_button.visible = false
			portfolio_button.visible = false
			journey_panel.visible = false
			stage_states["SEE"] = "AVAILABLE"
		_:
			_state_name = STATE_FIRST_LAUNCH
			_apply_view_model({})
			return

	stage_indicator.call("set_stage_states", stage_states)

func _apply_returning_stage_states(stage_states: Dictionary, current_stage: String) -> void:
	var order := ["SEE", "EXPLORE", "SOLVE", "INTEGRATE"]
	var current_index := maxi(0, order.find(current_stage))
	for i in range(order.size()):
		if i < current_index:
			stage_states[order[i]] = "COMPLETE"
		elif i == current_index:
			stage_states[order[i]] = "CURRENT"
		elif i == current_index + 1:
			stage_states[order[i]] = "AVAILABLE"
		else:
			stage_states[order[i]] = "LOCKED"

func _on_primary_pressed() -> void:
	match _state_name:
		STATE_FIRST_LAUNCH:
			_show_modal("Mulai Perjalanan", "Main Journey Hub belum dihubungkan pada tahap ini.\n\nImplementasi saat ini difokuskan pada Splash Loader dan Main Menu sesuai baseline JOSESI 01.", Callable())
		STATE_RETURNING_PLAYER:
			_show_modal("Lanjutkan Perjalanan", "Resume target akan diarahkan ke Main Journey Hub pada tahap berikutnya.\n\nUntuk sekarang, UI dan state menu sudah aktif sebagai baseline navigasi.", Callable())
		STATE_COMPLETED_JOURNEY:
			_show_modal("Perjalanan Selesai", "Tinjauan Journey Showcase akan dihubungkan setelah Main Journey Hub dan galeri akhir tersedia.", Callable())
		STATE_SAVE_LOAD_ERROR:
			_show_modal("Mulai Ulang", "Silakan mulai perjalanan baru setelah sistem save/load tahap berikutnya dihubungkan.", Callable())

func _on_new_journey_pressed() -> void:
	_show_modal("Perjalanan Baru", "Memulai ulang perjalanan akan diterapkan setelah sistem progress utama tersedia.", Callable())

func _on_portfolio_pressed() -> void:
	_show_modal("Portofolio", "Panel portofolio penuh akan dihubungkan setelah artefak Level 1–4 tersedia.", Callable())

func _on_settings_pressed() -> void:
	_show_modal("Pengaturan", "Kontrol pengaturan penuh akan dihubungkan pada tahap berikutnya.\n\nSaat ini menu mempertahankan placeholder editable-hybrid.", Callable())

func _on_about_pressed() -> void:
	_show_modal("Tentang JOSESI", "JOSESI adalah game 2D berbasis perjalanan studi mahasiswa DKV yang merepresentasikan SEE → EXPLORE → SOLVE → INTEGRATE.", Callable())

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
	modal_confirm.grab_focus()

func _close_modal() -> void:
	modal_overlay.visible = false
	modal_panel.visible = false
	_deferred_action = Callable()
	primary_button.grab_focus()

func _on_modal_confirmed() -> void:
	var action := _deferred_action
	_close_modal()
	if action.is_valid():
		action.call()