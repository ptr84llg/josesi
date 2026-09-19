extends Control

@export_range(0.0, 1.0, 0.001) var progress: float:
	get:
		return _progress
	set(value):
		_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _progress := 0.0

@export var future_color := Color(0.35, 0.50, 0.70, 0.42)
@export var node_outline_color := Color(0.78, 0.86, 0.96, 0.95)
@export var line_width := 4.0
@export var glow_width := 12.0
@export var transition_glow_multiplier := 1.0

const TRACE_COLORS := [
	Color("2c67f2"),
	Color("29b3ff"),
	Color("60d8e7"),
	Color("f4c43a"),
	Color("ff7a3a"),
]

var _transition_mode := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_progress(value: float) -> void:
	progress = value

func set_transition_mode(enabled: bool) -> void:
	_transition_mode = enabled
	transition_glow_multiplier = 1.55 if enabled else 1.0
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var points := _build_trace_points()
	if points.size() < 2:
		return

	draw_polyline(points, future_color, 3.0, true)

	var segment_count := points.size() - 1
	var completed_segments := clampi(int(floor(progress * float(segment_count))), 0, segment_count)
	for i in range(completed_segments):
		var t := float(i) / maxf(1.0, float(segment_count - 1))
		var color := _gradient_color(t)
		var glow := Color(color.r, color.g, color.b, 0.20)
		draw_line(points[i], points[i + 1], glow, glow_width * transition_glow_multiplier, true)
		draw_line(points[i], points[i + 1], color, line_width, true)

	if progress > 0.0:
		var exact_index := clampf(progress * float(segment_count), 0.0, float(segment_count))
		var low := clampi(int(floor(exact_index)), 0, segment_count - 1)
		var local_t := exact_index - float(low)
		var cursor := points[low].lerp(points[low + 1], local_t)
		var cursor_color := _gradient_color(progress)
		draw_circle(cursor, 14.0 * transition_glow_multiplier, Color(cursor_color.r, cursor_color.g, cursor_color.b, 0.20))
		draw_circle(cursor, 8.0, cursor_color)
		draw_arc(cursor, 11.0, 0.0, TAU, 32, node_outline_color, 2.0, true)

	_draw_endpoint(points[0], progress > 0.01, TRACE_COLORS[0])
	_draw_endpoint(points[points.size() - 1], progress >= 0.999, TRACE_COLORS[TRACE_COLORS.size() - 1])

func _build_trace_points() -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := 80
	var left := 16.0
	var right := maxf(left + 1.0, size.x - 16.0)
	var center_y := size.y * 0.50
	for i in range(count):
		var t := float(i) / float(count - 1)
		var x := lerpf(left, right, t)
		var wave := sin(t * TAU * 1.15) * 7.0 + sin(t * TAU * 2.40 + 0.7) * 2.5
		result.append(Vector2(x, center_y + wave))
	return result

func _gradient_color(t: float) -> Color:
	var clamped := clampf(t, 0.0, 1.0)
	var scaled := clamped * float(TRACE_COLORS.size() - 1)
	var index := clampi(int(floor(scaled)), 0, TRACE_COLORS.size() - 2)
	return TRACE_COLORS[index].lerp(TRACE_COLORS[index + 1], scaled - float(index))

func _draw_endpoint(position: Vector2, active: bool, active_color: Color) -> void:
	var fill := active_color if active else Color(0.18, 0.30, 0.48, 0.90)
	draw_circle(position, 8.0, fill)
	draw_arc(position, 10.0, 0.0, TAU, 32, node_outline_color, 2.0, true)
