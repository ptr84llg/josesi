extends Control
class_name JosesiActionButton

signal pressed

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
@onready var notification: TextureRect = $Notification
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
	notification.texture = notification_texture
	notification.visible = notification_visible
	if variant == "PRIMARY":
		label.add_theme_color_override("font_color", Color("08264a"))
	else:
		label.add_theme_color_override("font_color", Color("f4f9ff"))

func _on_hover_entered() -> void:
	skin.modulate = Color(1.08, 1.08, 1.08, 1.0)

func _on_hover_exited() -> void:
	skin.modulate = Color.WHITE

func _on_button_down() -> void:
	skin.modulate = Color(0.90, 0.90, 0.90, 1.0)

func _on_button_up() -> void:
	skin.modulate = Color(1.08, 1.08, 1.08, 1.0) if hit_button.is_hovered() else Color.WHITE
