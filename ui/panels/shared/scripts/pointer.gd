class_name PointerSprite extends Sprite2D

var pointer_offset : Vector2

func _ready() -> void:
	texture = load("res://addons/godot-xr-tools/images/teleport_target.png")
	scale = Vector2(.14,.14)


func _process(_delta: float) -> void:
	position = get_global_mouse_position() + pointer_offset
