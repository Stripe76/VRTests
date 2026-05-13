class_name PersonButton extends Button

@onready var _notifier : VisibleOnScreenNotifier2D = $Notifier

var _personID : int
var _looksID : int
var _library : LibraryManager


func with_data(library : LibraryManager,personID: int,looksID: int) -> PersonButton:
	_personID = personID
	_looksID = looksID
	_library = library
	return self;


func _ready() -> void:
	_notifier.screen_entered.connect(screen_entered)
	
	#text = _library.Looks_GetTitle(_looksID)
	
	pressed.connect(func (): get_tree().call_group("Scene","select_person",_personID))


func screen_entered():
	if not icon:
		if _looksID >= 0:
			icon = _library.Looks_GetPreviewImage(_looksID)
		else:
			text = "+"
