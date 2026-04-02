extends Sprite2D

func _process(delta: float) -> void:
	var mousepos = get_local_mouse_position()
	position = mousepos
