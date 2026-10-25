class_name UI extends Control

@export var show_add_button : bool:
	set(value):
		if _person_selection:
			_person_selection.show_add_button = value
	get:
		if _person_selection:
			return _person_selection.show_add_button
		return false

var MAIN_MENU_SCENE : PackedScene = load("res://ui/menus/main.tscn")

var _library : LibraryManager
var _scene_manager : SceneManager

var _main_menu : Control
var _main_panel : Control
var _persons_list : Control

var _looks_selection
var _person_selection


func _init(library: LibraryManager,scene_manager: SceneManager,main_menu: Control,main_panel: Control,persons_list:Control) -> void:
	_library = library
	_scene_manager = scene_manager
	
	_main_menu = main_menu
	_main_panel = main_panel
	_persons_list = persons_list


func _ready() -> void:
	if _main_menu:
		_main_menu.add_child(MAIN_MENU_SCENE.instantiate())
	if _persons_list:
		if not _person_selection:
			_person_selection = load("res://ui/panels/person_selection.tscn").instantiate()
			_person_selection.set_scene_manager(_scene_manager)
			
		_persons_list.add_child(_person_selection)
	
	add_to_group("UI")


func set_main_panel(panel: String):
	if not _looks_selection:
		_looks_selection = load("res://ui/panels/looks_selection.tscn").instantiate()
		_looks_selection.library = _library
	
	if not _person_selection:
		_person_selection = load("res://ui/panels/person_selection.tscn").instantiate()
		_person_selection.set_scene_manager(_scene_manager)
	
	if panel == "person_looks":
		_persons_list.add_child(_person_selection)
		_main_panel.add_child(_looks_selection)
	elif panel == "person_skin":
		pass


func person_clicked(person_id: int):
	_scene_manager.select_person(person_id)


func floor_clicked(event_position: Vector3,camera_position: Vector3):
	#_scene_manager.set_person_position(camera_position,event_position)
	_scene_manager.walk_person_to(event_position)
