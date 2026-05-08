extends VBoxContainer

@export var sub_menu: BoxContainer

func set_buttons(menuItem: MenuItem,clear : bool = false):
	if clear:
		clear_buttons()
	for i : MenuItem in menuItem.get_children():
		var b = Button.new()
		b.text = i.title
		b.anchor_right = 1
		b.size_flags_horizontal = Control.SIZE_EXPAND
		b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		b.custom_minimum_size = Vector2(100,100)
		b.pressed.connect(func ():
			if i.command != "":
				if sub_menu:
					sub_menu.clear_buttons()
				get_tree().call_group("UI",i.command,i.parameter)
			elif sub_menu:
				sub_menu.set_buttons(i,true)
		)
		add_child(b)


func clear_buttons():
	var children = get_children()
	for c in children:
		c.free()
