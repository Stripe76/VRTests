@tool
extends Button

func _ready() -> void:
	var rect : ColorRect = get_child(0)
	rect.color = Color(rect.name)
	pressed.connect(_on_pressed)

	
func _on_pressed():
	var node : Control = get_parent().get_parent().find_child("Colors")
	for n in node.get_children():
		n.visible = n.name == name
