extends Control

@export_range(0.0, 1.0, 0.001) var progress: float = 0.0:
	set(value):
		progress = clamp(value, 0.0, 1.0)
		queue_redraw()

@export var amplitude: float = 18.0
@export var thickness: float = 7.0
@export var glow_thickness: float = 16.0
@export var show_nodes: bool = true
@export var line_start_ratio: float = 0.10
@export var line_end_ratio: float = 0.90

const COLOR_TRACK := Color(0.53, 0.67, 0.85, 0.30)
const GLOW_TRACK := Color(0.17, 0.48, 0.92, 0.12)
const NODE_OUTLINE := Color(0.89, 0.95, 1.0, 0.88)
const NODE_BG := Color(0.03, 0.10, 0.20, 0.96)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		queue_redraw()

func set_progress(value: float) -> void:
	progress = clamp(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var pts := _curve_points()
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], GLOW_TRACK, glow_thickness, true)
		draw_line(pts[i], pts[i + 1], COLOR_TRACK, 3.0, true)

	var visible_segments := maxi(1, int(round(progress * float(pts.size() - 1))))
	for i in range(min(visible_segments, pts.size() - 1)):
		var t := 0.0
		if visible_segments > 1:
			t = float(i) / float(visible_segments - 1)
		var color := _gradient_color(t)
		draw_line(pts[i], pts[i + 1], color.darkened(0.10), glow_thickness, true)
		draw_line(pts[i], pts[i + 1], color, thickness, true)

	if show_nodes:
		var nodes := _node_positions()
		for i in range(nodes.size()):
			var active := progress >= _node_progress_threshold(i)
			var node_color := _gradient_color(float(i) / maxf(1.0, float(nodes.size() - 1))) if active else Color(0.58, 0.67, 0.80, 0.55)
			draw_circle(nodes[i], 16.0, NODE_BG)
			draw_arc(nodes[i], 16.0, 0.0, TAU, 40, NODE_OUTLINE, 2.5, true)
			draw_circle(nodes[i], 9.0, node_color)

func _curve_points() -> PackedVector2Array:
	var arr := PackedVector2Array()
	var start_x := size.x * line_start_ratio
	var end_x := size.x * line_end_ratio
	var width_span := maxf(1.0, end_x - start_x)
	var base_y := size.y * 0.52
	var samples := 84
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var x := start_x + (width_span * t)
		var y := base_y + sin(t * TAU * 1.85) * amplitude * 0.55
		arr.append(Vector2(x, y))
	return arr

func _node_positions() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(size.x * line_start_ratio, size.y * 0.52),
		Vector2(size.x * 0.50, size.y * 0.45),
		Vector2(size.x * line_end_ratio, size.y * 0.55),
	])

func _node_progress_threshold(index: int) -> float:
	match index:
		0:
			return 0.02
		1:
			return 0.50
		_:
			return 0.98

func _gradient_color(t: float) -> Color:
	t = clamp(t, 0.0, 1.0)
	if t < 0.34:
		return Color(1.0, 0.37, 0.29, 1.0).lerp(Color(1.0, 0.86, 0.12, 1.0), t / 0.34)
	elif t < 0.68:
		return Color(1.0, 0.86, 0.12, 1.0).lerp(Color(0.15, 0.86, 0.54, 1.0), (t - 0.34) / 0.34)
	return Color(0.15, 0.86, 0.54, 1.0).lerp(Color(0.12, 0.69, 1.0, 1.0), (t - 0.68) / 0.32)