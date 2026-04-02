extends Control

@export var Menu: Node

func _ready() -> void:
	if Menu:
		$MainButtons/Buttons.set_buttons(Menu)
