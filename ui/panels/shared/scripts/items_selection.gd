class_name ItemsSelection extends ScrollContainer

var _library : LibraryManager
var _button_script : Script

var _items : Control 
var _min_button_size := Vector2(240,240)

signal item_selected


func _init(script: String):
	_button_script = load(script)


func _ready() -> void:
	update_items()


func _gui_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_CTRL):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				resize_buttons(1.05)
				event.canceled = true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				resize_buttons(0.95)
				event.canceled = true


func set_library(library: LibraryManager,update: bool = true) -> void:
	_library = library
	
	if update:
		update_items()
		
		resize_buttons(1)


func update_items() -> void:
	_items = get_node("Items")
	
	if _library and _items:
		for i in _get_count():
			var button : ItemButton = _button_script.new(_library,i)
			button.button_selected.connect(button_selected)
			_items.add_child(button)


func resize_buttons(delta: float):
	if _items:
		_min_button_size *= delta
		if _min_button_size.x < 100:
			_min_button_size = Vector2(100,100)
		elif _min_button_size.x > 360:
			_min_button_size = Vector2(360,360)
		for c in _items.get_children():
			c.custom_minimum_size = _min_button_size


func _get_count() -> int:
	return 0


func button_selected(_button: ItemButton,item_id: int):
	if item_selected:
		item_selected.emit(item_id)
