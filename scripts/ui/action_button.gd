extends Control
class_name JosesiActionButton

signal pressed

const PRIMARY_H_MARGIN := 32
const PRIMARY_V_MARGIN := 18
const SECONDARY_H_MARGIN := 28
const SECONDARY_V_MARGIN := 14

@export var primary_skin: Texture2D
@export var secondary_skin: Texture2D
@export var notification_texture: Texture2D

@export_enum("PRIMARY", "SECONDARY") var variant: String = "SECONDARY":
	set(value):
		variant = value
		if is_node_ready():
			_apply_visuals()

@export var text: String = "BUTTON":
	set(value):
		text = value
		if is_node_ready():
			$Label.text = value

@export var icon: Texture2D:
	set(value):
		icon = value
		if is_node_ready():
			$Icon.texture = value

@export var notification_visible: bool = false:
	set(value):
		notification_visible = value
		if is_node_ready():
			$Notification.visible = value

@onready var skin: NinePatchRect = $Skin
@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label
@onready var notification_badge: TextureRect = $Notification
@onready var hit_button: Button = $HitButton

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_visuals()
	hit_button.pressed.connect(_emit_pressed)
	hit_button.mouse_entered.connect(_on_hover_entered)
	hit_button.mouse_exited.connect(_on_hover_exited)
	hit_button.button_down.connect(_on_button_down)
	hit_button.button_up.connect(_on_button_up)

func focus_button() -> void:
	hit_button.grab_focus()

func _emit_pressed() -> void:
	pressed.emit()

func _apply_visuals() -> void:
	if skin == null:
		return
	skin.texture = primary_skin if variant == "PRIMARY" else secondary_skin
	label.text = text
	icon_rect.texture = icon
	notification_badge.texture = notification_texture
	notification_badge.visible = notification_visible

	if variant == "PRIMARY":
		skin.patch_margin_left = PRIMARY_H_MARGIN
		skin.patch_margin_top = PRIMARY_V_MARGIN
		skin.patch_margin_right = PRIMARY_H_MARGIN
		skin.patch_margin_bottom = PRIMARY_V_MARGIN
		icon_rect.position = Vector2(22.0, 10.0)
		icon_rect.size = Vector2(48.0, 48.0)
		icon_rect.modulate = Color("163a5f")
		label.offset_left = 86.0
		label.offset_right = -24.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_constant_override("outline_size", 0)
		label.add_theme_color_override("font_color", Color("08264a"))
	else:
		skin.patch_margin_left = SECONDARY_H_MARGIN
		skin.patch_margin_top = SECONDARY_V_MARGIN
		skin.patch_margin_right = SECONDARY_H_MARGIN
		skin.patch_margin_bottom = SECONDARY_V_MARGIN
		icon_rect.position = Vector2(20.0, 6.0)
		icon_rect.size = Vector2(40.0, 40.0)
		icon_rect.modulate = Color(0.88, 0.94, 1.0, 0.96)
		label.offset_left = 82.0
		label.offset_right = -28.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(0.005, 0.035, 0.09, 0.72))
		label.add_theme_color_override("font_color", Color("f7fbff"))

func _on_hover_entered() -> void:
	skin.modulate = Color(1.04, 1.04, 1.04, 1.0)

func _on_hover_exited() -> void:
	skin.modulate = Color.WHITE

func _on_button_down() -> void:
	skin.modulate = Color(0.94, 0.94, 0.94, 1.0)

func _on_button_up() -> void:
	skin.modulate = Color(1.04, 1.04, 1.04, 1.0) if hit_button.is_hovered() else Color.WHITE
