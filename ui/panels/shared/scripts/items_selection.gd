class_name ItemsSelection extends ScrollContainer

var _library : LibraryManager
var _button_script : Script

var _items : Control 

signal item_selected


func _init(script: String):
	_button_script = load(script)


func _ready() -> void:
	update_items()


func set_library(library: LibraryManager,update: bool = true) -> void:
	_library = library
	
	if update:
		update_items()


func update_items() -> void:
	_items = get_node("Items")
	
	if _library and _items:
		for i in _get_count():
			var button : ItemButton = _button_script.new(_library,i)
			button.button_selected.connect(button_selected)
			_items.add_child(button)


func _get_count() -> int:
	return 0


func button_selected(_button: ItemButton,item_id: int):
	if item_selected:
		item_selected.emit(item_id)
