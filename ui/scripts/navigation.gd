extends Control

@export var menu: Node

func _ready() -> void:
	if menu:
		$MainButtons/Buttons.set_buttons(menu)
