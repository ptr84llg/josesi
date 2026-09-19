extends Control

const TARGET_SCENE := "res://scenes/menu/main_menu.tscn"
const PHASES := [
	{"label": "Menyiapkan antarmuka...", "progress": 0.18},
	{"label": "Memuat identitas visual...", "progress": 0.42},
	{"label": "Menyelaraskan perjalanan...", "progress": 0.68},
	{"label": "Menyiapkan menu utama...", "progress": 0.86},
	{"label": "Hampir siap...", "progress": 0.98},
]

@onready var headline_label: Label = $SafeArea/ContentStack/StatusStack/HeadlineLabel
@onready var status_label: Label = $SafeArea/ContentStack/StatusStack/StatusLabel
@onready var percent_label: Label = $SafeArea/ContentStack/LoaderStack/PercentLabel
@onready var trace: Control = $SafeArea/ContentStack/LoaderStack/JourneyTrace
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var version_label: Label = $Footer/VersionLabel

var _phase_index: int = 0
var _phase_elapsed: float = 0.0
var _display_progress: float = 0.0
var _transitioning: bool = false
var _loaded_resource: PackedScene

func _ready() -> void:
	headline_label.text = "MENYIAPKAN PERJALANAN"
	status_label.text = PHASES[0].label
	percent_label.text = "0%"
	version_label.text = "JOSESI v0.1.1 • DEVELOPMENT BUILD"
	fade_rect.modulate.a = 1.0
	trace.call("set_progress", 0.0)
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	set_process(true)
	call_deferred("_load_target_scene")

func _process(delta: float) -> void:
	_phase_elapsed += delta
	_update_target_phase()
	_update_loader_progress(delta)
	if _can_finish_loading():
		_begin_transition()

func _update_target_phase() -> void:
	if _phase_index >= PHASES.size() - 1:
		return
	var current_target := float(PHASES[_phase_index].progress)
	if _display_progress >= current_target - 0.01 and _phase_elapsed >= 0.40:
		_phase_index += 1
		_phase_elapsed = 0.0
		status_label.text = str(PHASES[_phase_index].label)

func _update_loader_progress(delta: float) -> void:
	var phase_target: float = float(PHASES[_phase_index].progress)
	var loader_target: float = 1.0 if _loaded_resource != null else phase_target
	_display_progress = move_toward(_display_progress, loader_target, delta * 0.42)
	trace.call("set_progress", _display_progress)
	percent_label.text = "%d%%" % int(round(_display_progress * 100.0))

func _load_target_scene() -> void:
	if _loaded_resource != null:
		return
	var resource: Resource = ResourceLoader.load(TARGET_SCENE, "PackedScene")
	if resource is PackedScene:
		_loaded_resource = resource as PackedScene
		print("JOSESI_SPLASH_TARGET_LOAD_READY=TRUE mode=DEFERRED_SYNC")
		return
	push_error("JOSESI_SPLASH_TARGET_LOAD_READY=FALSE reason=target_scene_load_failed")

func is_target_scene_ready() -> bool:
	return _loaded_resource != null

func _can_finish_loading() -> bool:
	return _loaded_resource != null and _display_progress >= 0.995 and not _transitioning

func _begin_transition() -> void:
	if _transitioning:
		return
	_transitioning = true
	headline_label.text = "PERJALANAN SIAP"
	status_label.text = "Memasuki Journey Portal..."
	percent_label.text = "100%"
	trace.call("set_progress", 1.0)
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_go_to_main_menu)

func _go_to_main_menu() -> void:
	if _loaded_resource == null:
		push_error("Splash transition requested without loaded main menu scene.")
		return
	get_tree().change_scene_to_packed(_loaded_resource)
