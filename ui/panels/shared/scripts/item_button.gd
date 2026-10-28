class_name ItemButton extends Button

var _item_id : int
var _library : LibraryManager
var _notifier : VisibleOnScreenNotifier2D

signal button_selected


func _init(library : LibraryManager,id: int) -> void:
	_item_id = id
	_library = library


func _ready() -> void:
	_notifier = VisibleOnScreenNotifier2D.new()
	_notifier.name = "Notifier"
	add_child(_notifier)
	
	_notifier.screen_entered.connect(screen_entered)
	
	#text = _library.Looks_GetTitle(_looksID)
	
	pressed.connect(func (): button_selected.emit(_item_id))

	clip_text = true
	expand_icon = true
	custom_minimum_size = Vector2(230,230)



func _get_icon_image(item_id: int) -> Texture2D:
	return _library.Clothes_GetPreviewImage(item_id)


func screen_entered():
	if not icon:
		icon = _get_icon_image(_item_id)
