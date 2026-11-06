extends Control

@onready var menu: MenuItem = $Menu

func _ready() -> void:
	$MainButtons/Buttons.set_buttons(menu)


func set_selected_item(parameter: String,sub_parameter: String):
	if menu:
		for i : MenuItem in menu.get_children():
			var unselect : bool = true
			for s : MenuItem in i.get_children():
				if s.parameter == parameter and s.sub_parameter == sub_parameter:
					if i.button and not i.button.is_selected:
						i.button.pressed.emit()
					if s.button:
						unselect = false
						s.button.is_selected = true
						i.button.is_selected = true
				elif s.button:
					s.button.is_selected = false
			if unselect and i.button:
				i.button.is_selected = false
