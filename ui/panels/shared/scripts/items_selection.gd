class_name ItemsSelection extends ScrollContainer

@export var items_filter : String:
	set(value):
		_filter = value
		
		update_items()
	get:
		return _filter

var _filter : String = ""

var _library : LibraryManager
var _button_script : Script

var _items : Control 
var _min_button_size := Vector2(240,240)

signal item_selected


func _init(script: String):
	_button_script = load(script)


func _ready() -> void:
	_items = get_node("Items")
	
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
	if _library and _items:
		var children := _items.get_children( )
		var item_count := _get_count(_filter)
		var child_count := _items.get_child_count()
		for i in min(child_count,item_count):
			var button : ItemButton = children[i]
			button._item_filter = _filter
			button.change_item_id(i,_map_index_to_id(_filter,i))
		if child_count > item_count:
			for i in child_count - item_count:
				_items.remove_child(children[item_count+i])
		if child_count < item_count:
			for i in item_count - child_count:
				var button : ItemButton = _button_script.new(_library,child_count+i,_map_index_to_id(_filter,child_count+i),_filter,_min_button_size)
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


func _get_count(__filter: String) -> int:
	return 0


func _map_index_to_id(_filter_: String,index: int) -> int:
	return index


func button_selected(_button: ItemButton,item_id: int):
	if item_selected:
		item_selected.emit(item_id)
