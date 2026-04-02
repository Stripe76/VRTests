@tool
extends Button

func _ready() -> void:
	var rect : ColorRect = get_child(0)
	rect.color = Color(name)
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	get_tree().call_group("Global_UI","_skin_color_picked",get_child(0).color)
