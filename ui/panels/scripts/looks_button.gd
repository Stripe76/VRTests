class_name LooksButton
extends Button

@onready var _notifier : VisibleOnScreenNotifier2D = $Notifier

var _looksID : int
var _library : LibraryManager


func with_data(library : LibraryManager,id: int) -> LooksButton:
	_looksID = id
	_library = library
	return self;


func _init() -> void:
	custom_minimum_size = Vector2(100,100)


func _ready() -> void:
	_notifier.screen_entered.connect(screen_entered)
	
	text = _library.Looks_GetTitle(_looksID)
	
	pressed.connect(func (): get_tree().call_group("Scene","select_looks",_looksID))


func screen_entered():
	if not icon:
		icon = _library.Looks_GetPreviewImage(_looksID)
