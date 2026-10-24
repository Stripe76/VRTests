extends Control

@onready var _selection := $Selection
@onready var _main_panel := $Main/Panels/MainPanel

var _library := LibraryManager.new()
var _scene_manager : SceneManager

var _looks_selection
var _person_selection


func _ready() -> void:
	theme = load("res://resources/theme.tres")
	
	_library.LoadData("/mnt/data/Games/Virtamate/AddonPackages/")


func get_library( ) -> LibraryManager:
	return _library


func set_scene_manager(scene_manager: SceneManager):
	_scene_manager = scene_manager


func set_main_panel(_panel: String):
	if not _looks_selection:
		_looks_selection = load("res://ui/panels/looks_selection.tscn").instantiate()
		_looks_selection.library = _library
	
	if not _person_selection:
		_person_selection = load("res://ui/panels/person_selection.tscn").instantiate()
		_person_selection.set_scene_manager(_scene_manager)
	
	_selection.add_child(_person_selection)
	_main_panel.add_child(_looks_selection)


func person_clicked(person_id: int):
	_scene_manager.select_person(person_id)


func floor_clicked(event_position: Vector3,camera_position: Vector3):
	_scene_manager.set_person_position(camera_position,event_position)
