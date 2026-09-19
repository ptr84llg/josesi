extends Control
class_name JosesiJourneyTrace

@export_range(0.0, 1.0, 0.001) var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_update_visuals()

@onready var reveal_clip: Control = $RevealClip
@onready var fill: TextureRect = $RevealClip/Fill
@onready var current_node: TextureRect = $CurrentNode

const CURVE_POINTS: Array[Vector2] = [
	Vector2(0.03, 0.50),
	Vector2(0.10, 0.49),
	Vector2(0.20, 0.35),
	Vector2(0.30, 0.44),
	Vector2(0.40, 0.59),
	Vector2(0.50, 0.68),
	Vector2(0.60, 0.57),
	Vector2(0.68, 0.41),
	Vector2(0.80, 0.35),
	Vector2(0.90, 0.49),
	Vector2(0.97, 0.50),
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_visuals()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_visuals()

func set_progress(value: float) -> void:
	progress = value

func _update_visuals() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	reveal_clip.position = Vector2.ZERO
	reveal_clip.size = Vector2(size.x * progress, size.y)
	fill.position = Vector2.ZERO
	fill.size = size
	var point := _sample_curve(progress)
	var node_size := current_node.size
	current_node.position = Vector2(point.x * size.x, point.y * size.y) - node_size * 0.5
	current_node.visible = progress > 0.035 and progress < 0.985

func _sample_curve(value: float) -> Vector2:
	var t: float = clampf(value, 0.0, 1.0)
	if t <= CURVE_POINTS[0].x:
		return CURVE_POINTS[0]
	for i in range(CURVE_POINTS.size() - 1):
		var a: Vector2 = CURVE_POINTS[i]
		var b: Vector2 = CURVE_POINTS[i + 1]
		if t <= b.x:
			var local_t: float = inverse_lerp(a.x, b.x, t)
			return a.lerp(b, local_t)
	return CURVE_POINTS[CURVE_POINTS.size() - 1]
