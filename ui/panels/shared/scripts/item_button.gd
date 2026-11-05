class_name ItemButton extends Button

var _item_id : int
var _item_index : int
var _item_filter : String

var _library : LibraryManager
var _min_size : Vector2

signal button_selected
signal button_middle_selected


func _init(library : LibraryManager,index: int,id: int,filter: String = "",min_size:= Vector2(200,200)) -> void:
	_item_id = id
	_item_index = index
	_item_filter = filter
	_library = library
	_min_size = min_size


func _ready() -> void:
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.name = "Notifier"
	add_child(notifier)
	
	notifier.screen_entered.connect(screen_entered)
	
	pressed.connect(func (): button_selected.emit(self,_item_id))
	
	clip_text = true
	expand_icon = true
	custom_minimum_size = _min_size


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			button_middle_selected.emit(self,_item_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _get_drag_info():
		var control: Control = Control.new()
		var preview: TextureRect = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		preview.texture = icon
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.position = Vector2(-50,-50)
		control.size = Vector2(100,100)
		control.add_child(preview)
		set_drag_preview(control)
		return _get_drag_info()
	return null


func _get_icon_image(__item_id: int) -> Texture2D:
	return Texture2D.new()


func _get_drag_info():
	return null


func change_item_id(index: int,item_id: int):
	_item_id = item_id
	_item_index = index
	
	if icon:
		icon = null
		screen_entered()


func screen_entered():
	if not icon:
		icon = _get_icon_image(_item_id)
