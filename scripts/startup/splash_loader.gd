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
var _resource_status: int = ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
var _loaded_resource: PackedScene

func _ready() -> void:
	headline_label.text = "MENYIAPKAN PERJALANAN"
	status_label.text = PHASES[0].label
	percent_label.text = "0%"
	version_label.text = "JOSESI v0.1.1 • DEVELOPMENT BUILD"
	fade_rect.modulate.a = 1.0
	trace.call("set_progress", 0.0)
	ResourceLoader.load_threaded_request(TARGET_SCENE)
	create_tween().tween_property(fade_rect, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	set_process(true)

func _process(delta: float) -> void:
	_phase_elapsed += delta
	_update_target_phase(delta)
	_update_loader_progress(delta)
	_poll_threaded_load()
	if _can_finish_loading():
		_begin_transition()

func _update_target_phase(_delta: float) -> void:
	if _phase_index >= PHASES.size() - 1:
		return
	var current_target := float(PHASES[_phase_index].progress)
	if _display_progress >= current_target - 0.01 and _phase_elapsed >= 0.40:
		_phase_index += 1
		_phase_elapsed = 0.0
		status_label.text = str(PHASES[_phase_index].label)

func _update_loader_progress(delta: float) -> void:
	var phase_target := float(PHASES[_phase_index].progress)
	var loader_target := phase_target
	if _resource_status == ResourceLoader.THREAD_LOAD_LOADED:
		loader_target = 1.0
	elif _resource_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var progress_array := []
		ResourceLoader.load_threaded_get_status(TARGET_SCENE, progress_array)
		if progress_array.size() > 0:
			loader_target = maxf(loader_target, clamp(float(progress_array[0]), 0.0, 1.0) * 0.96)
	_display_progress = move_toward(_display_progress, loader_target, delta * 0.42)
	trace.call("set_progress", _display_progress)
	percent_label.text = "%d%%" % int(round(_display_progress * 100.0))

func _poll_threaded_load() -> void:
	if _loaded_resource != null:
		return
	_resource_status = ResourceLoader.load_threaded_get_status(TARGET_SCENE)
	if _resource_status == ResourceLoader.THREAD_LOAD_LOADED:
		_loaded_resource = ResourceLoader.load_threaded_get(TARGET_SCENE) as PackedScene

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