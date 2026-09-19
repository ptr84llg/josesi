extends Control

const STAGES: Array[String] = ["SEE", "EXPLORE", "SOLVE", "INTEGRATE"]
const COLOR_COMPLETE := Color("1ca7ff")
const COLOR_CURRENT := Color("ff9f1c")
const COLOR_AVAILABLE := Color("6dc7ff")
const COLOR_LOCKED := Color("7e8a98")
const COLOR_LINE := Color(0.30, 0.48, 0.62, 0.72)

var _stage_states := {
	"SEE": "AVAILABLE",
	"EXPLORE": "LOCKED",
	"SOLVE": "LOCKED",
	"INTEGRATE": "LOCKED",
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_label_layout()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_label_layout()
		queue_redraw()

func set_stage_states(states: Dictionary) -> void:
	for stage in STAGES:
		if states.has(stage):
			_stage_states[stage] = str(states[stage])
	_update_label_colors()
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var points := _node_positions()
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], COLOR_LINE, 3.0, true)
	for i in range(points.size()):
		var stage := STAGES[i]
		var state := str(_stage_states.get(stage, "LOCKED"))
		var color := _color_for_state(state)
		draw_circle(points[i], 14.0, Color(0.02, 0.10, 0.18, 0.96))
		draw_arc(points[i], 15.0, 0.0, TAU, 32, color, 3.0, true)
		if state == "COMPLETE":
			draw_line(points[i] + Vector2(-6, 0), points[i] + Vector2(-1, 5), color, 3.0, true)
			draw_line(points[i] + Vector2(-1, 5), points[i] + Vector2(7, -5), color, 3.0, true)
		elif state == "CURRENT":
			draw_circle(points[i], 7.0, color)
		elif state == "AVAILABLE":
			draw_circle(points[i], 4.0, color)

func _node_positions() -> PackedVector2Array:
	var y := 24.0
	return PackedVector2Array([
		Vector2(size.x * 0.10, y),
		Vector2(size.x * 0.37, y),
		Vector2(size.x * 0.64, y),
		Vector2(size.x * 0.91, y),
	])

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

func _update_label_colors() -> void:
	for stage in STAGES:
		var label := get_node_or_null(stage + "Label") as Label
		if label != null:
			label.add_theme_color_override("font_color", _color_for_state(str(_stage_states.get(stage, "LOCKED"))))

func _update_label_layout() -> void:
	if not is_inside_tree():
		return
	var points := _node_positions()
	for i in range(STAGES.size()):
		var label := get_node_or_null(STAGES[i] + "Label") as Label
		if label != null:
			label.position = Vector2(points[i].x - 48.0, 45.0)
			label.size = Vector2(96.0, 24.0)
