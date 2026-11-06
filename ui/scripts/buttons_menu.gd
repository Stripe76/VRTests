extends VBoxContainer

@export var sub_menu: BoxContainer

func set_buttons(menuItem: MenuItem,clear: bool = false):
	if clear:
		clear_buttons()
	for i : MenuItem in menuItem.get_children():
		var b = MenuItemButton.new()
		b.text = i.name_override if not i.name_override.is_empty() else str(i.name)
		b.drag_data = i.drag_data_type
		b.drag_filter = i.sub_parameter
		
		b.anchor_right = 1
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.size_flags_horizontal = Control.SIZE_EXPAND
		b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		b.custom_minimum_size = Vector2(100,100)
		
		b.pressed.connect(func ():
			if i.command != "":
				if sub_menu:
					sub_menu.clear_buttons()
				get_tree().call_group("UI",i.command,i.parameter,i.sub_parameter)
			elif sub_menu:
				sub_menu.set_buttons(i,true)
		)
		b.drop_request.connect(func ():
			if sub_menu and i.command == "":
				sub_menu.set_buttons(i,true)
		)
		i.button = b
		
		add_child(b)


func clear_buttons():
	for c in get_children():
		c.queue_free()
