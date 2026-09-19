extends Control
class_name JosesiStageProgressStrip

const STAGES: Array[String] = ["SEE", "EXPLORE", "SOLVE", "INTEGRATE"]
@export var complete_texture: Texture2D
@export var current_texture: Texture2D
@export var available_texture: Texture2D
@export var locked_texture: Texture2D

const COLOR_COMPLETE := Color("2e9cff")
const COLOR_CURRENT := Color("ff9f1c")
const COLOR_AVAILABLE := Color("6fd4ff")
const COLOR_LOCKED := Color("93a5bd")
const COLOR_LINE := Color(0.36, 0.60, 0.78, 0.62)

var _states := {
	"SEE": "AVAILABLE",
	"EXPLORE": "LOCKED",
	"SOLVE": "LOCKED",
	"INTEGRATE": "LOCKED",
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_layout()
	_update_visuals()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_layout()
		queue_redraw()

func set_stage_states(states: Dictionary) -> void:
	for stage in STAGES:
		if states.has(stage):
			_states[stage] = str(states[stage])
	_update_visuals()

func _draw() -> void:
	if size.x <= 1.0:
		return
	var points := _positions()
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], COLOR_LINE, 3.0, true)

func _positions() -> PackedVector2Array:
	var y := 24.0
	return PackedVector2Array([
		Vector2(size.x * 0.08, y),
		Vector2(size.x * 0.36, y),
		Vector2(size.x * 0.64, y),
		Vector2(size.x * 0.92, y),
	])

func _update_layout() -> void:
	if not is_inside_tree():
		return
	var points := _positions()
	for i in range(STAGES.size()):
		var icon_rect := get_node(STAGES[i] + "Icon") as TextureRect
		var label := get_node(STAGES[i] + "Label") as Label
		icon_rect.position = points[i] - Vector2(21.0, 21.0)
		icon_rect.size = Vector2(42.0, 42.0)
		label.position = Vector2(points[i].x - 45.0, 49.0)
		label.size = Vector2(90.0, 24.0)
	queue_redraw()

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	for stage in STAGES:
		var state := str(_states.get(stage, "LOCKED"))
		var icon_rect := get_node(stage + "Icon") as TextureRect
		var label := get_node(stage + "Label") as Label
		icon_rect.texture = _texture_for_state(state)
		label.add_theme_color_override("font_color", _color_for_state(state))
	queue_redraw()

func _texture_for_state(state: String) -> Texture2D:
	match state:
		"COMPLETE":
			return complete_texture
		"CURRENT":
			return current_texture
		"AVAILABLE":
			return available_texture
		_:
			return locked_texture

func _color_for_state(state: String) -> Color:
	match state:
		"COMPLETE":
			return COLOR_COMPLETE
		"CURRENT":
			return COLOR_CURRENT
		"AVAILABLE":
			return COLOR_AVAILABLE
		_:
			return COLOR_LOCKED
