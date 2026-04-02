extends VBoxContainer

@export var SubMenu: BoxContainer

func set_buttons(menuItem: MenuItem,clear : bool = false):	
	if clear:
		clear_buttons()	
	for i : MenuItem in menuItem.get_children():
		var b = Button.new()
		b.text = i.Title
		b.anchor_right = 1
		b.size_flags_horizontal = Control.SIZE_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		b.custom_minimum_size = Vector2(100,200)
		b.pressed.connect(func ():
			if i.Command != "":
				if SubMenu:
					SubMenu.clear_buttons()
				get_tree().call_group("UI",i.Command,i.Parameter)
			elif SubMenu:
				SubMenu.set_buttons(i,true)
		)
		add_child(b)

func clear_buttons():
	var children = get_children()	
	for c in children:
		c.free()
