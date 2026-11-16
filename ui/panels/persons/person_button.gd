class_name PersonButton extends Button

@export var is_selected : bool:
	set(value):
		is_selected = value
		
		theme_type_variation = "SelectedButton" if is_selected else ""
	get:
		return is_selected

var _personID : int
var _looksID : int
var _library : LibraryManager

var _min_size := Vector2(100,100)

signal button_selected
signal button_middle_selected


func with_data(library : LibraryManager,personID: int,looksID: int) -> PersonButton:
	_personID = personID
	_looksID = looksID
	_library = library
	return self;


func _ready() -> void:
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.name = "Notifier"
	add_child(notifier)
	
	notifier.screen_entered.connect(screen_entered)
	
	pressed.connect(func (): button_selected.emit(self,_personID))
	
	clip_text = true
	expand_icon = true
	custom_minimum_size = _min_size


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			button_middle_selected.emit(self,_personID)


func screen_entered():
	if not icon:
		if _looksID >= 0:
			icon = _library.Looks_GetPreviewImage(_looksID)
		else:
			text = "+"
