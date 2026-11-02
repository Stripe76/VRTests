class_name ItemButton extends Button

var _item_id : int
var _library : LibraryManager
var _notifier : VisibleOnScreenNotifier2D
var _min_size : Vector2

signal button_selected
signal button_middle_selected


func _init(library : LibraryManager,id: int,min_size:= Vector2(200,200)) -> void:
	_item_id = id
	_library = library
	_min_size = min_size


func _ready() -> void:
	_notifier = VisibleOnScreenNotifier2D.new()
	_notifier.name = "Notifier"
	add_child(_notifier)
	
	_notifier.screen_entered.connect(screen_entered)
	
	pressed.connect(func (): button_selected.emit(self,_item_id))
	
	clip_text = true
	expand_icon = true
	custom_minimum_size = _min_size


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			button_middle_selected.emit(self,_item_id)


func _get_icon_image(item_id: int) -> Texture2D:
	return Texture2D.new()


func change_item_id(item_id: int):
	_item_id = item_id
	
	if icon:
		icon = null
		screen_entered()


func screen_entered():
	if not icon:
		icon = _get_icon_image(_item_id)
