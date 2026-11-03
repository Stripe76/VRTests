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
var PERSON_SELECTION_SCENE : PackedScene = load("res://ui/panels/person_selection.tscn")

var _library : LibraryManager
var _scene_manager : SceneManager

var _main_menu : Control
var _main_panel : Control
var _persons_list : Control

var _person_selection


func _init(library: LibraryManager,scene_manager: SceneManager,main_menu: Control,main_panel: Control,persons_list:Control,focus_camera: Node3D) -> void:
	_library = library
	_scene_manager = scene_manager
	
	_main_menu = main_menu
	_main_panel = main_panel
	_persons_list = persons_list
	
	_scene_manager.focus_camera = focus_camera.get_path()


func _ready() -> void:
	if _main_menu:
		_main_menu.add_child(MAIN_MENU_SCENE.instantiate())
	if _persons_list:
		if not _person_selection:
			_person_selection = PERSON_SELECTION_SCENE.instantiate()
			_person_selection.set_scene_manager(_scene_manager)
			
		_persons_list.add_child(_person_selection)
	
	_scene_manager.current_person_changed.connect(current_person_changed)
	
	add_to_group("UI")
	set_main_panel("looks","all");


func set_main_panel(panel: String,_sub_panel: String):
	var found := _main_panel.find_child(panel)
	if not found:
		var scene = load("res://ui/panels/"+panel+"/"+panel+".tscn").instantiate().with(_library,_scene_manager,)
		scene.name = panel
		
		_main_panel.add_child(scene)
	
	for c : Control in _main_panel.get_children():
		c.visible = c.name == panel


func current_person_changed(scene_manager: SceneManager):
	if scene_manager:
		if scene_manager.current_person_id < 0:
			set_main_panel("looks","all");
		scene_manager.set_focus_camera("hip")


func person_clicked(person_id: int):
	_scene_manager.select_person(person_id)


func floor_clicked(event_position: Vector3,camera_position: Vector3):
	#_scene_manager.set_person_position(camera_position,event_position)
	_scene_manager.walk_person_to(event_position)
