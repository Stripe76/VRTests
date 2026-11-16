class_name UI extends Node

@export var show_add_button : bool:
	set(value):
		if _person_selection:
			_person_selection.show_add_button = value
	get:
		if _person_selection:
			return _person_selection.show_add_button
		return false
@export var pointer_sprite : Sprite2D

var TOP_MENU_SCENE : PackedScene = load("res://ui/menus/top.tscn")
var MAIN_MENU_SCENE : PackedScene = load("res://ui/menus/main.tscn")
var PERSON_SELECTION_SCENE : PackedScene = load("res://ui/panels/persons/person_selection.tscn")

var _library : LibraryManager
var _scene_manager : SceneManager

var _top_menu_panel : Node
var _main_menu_panel : Node
var _main_panel : Node
var _persons_list : Node

var _top_menu
var _main_menu
var _person_selection


func _init( library: LibraryManager,
			scene_manager: SceneManager,
			top_menu: Node,
			main_menu: Node,
			main_panel: Node,
			persons_list: Node,
			focus_camera: Node3D) -> void:
	name = "UIManager"
	
	_library = library
	_scene_manager = scene_manager
	
	_top_menu_panel = top_menu
	_main_menu_panel = main_menu
	_main_panel = main_panel
	_persons_list = persons_list
	
	if focus_camera:
		_scene_manager.focus_camera = focus_camera.get_path()


func _ready() -> void:
	if _top_menu_panel:
		_top_menu = TOP_MENU_SCENE.instantiate()
		_top_menu_panel.add_child(_top_menu)
	if _main_menu_panel:
		_main_menu = MAIN_MENU_SCENE.instantiate()
		_main_menu_panel.add_child(_main_menu)
		
		#if pointer_sprite:
			#_main_menu.add_child(pointer_sprite.duplicate())
	if _persons_list:
		if not _person_selection:
			_person_selection = PERSON_SELECTION_SCENE.instantiate()
			_person_selection.set_scene_manager(_scene_manager)
			
		_persons_list.add_child(_person_selection)
	
	_scene_manager.current_person_changed.connect(current_person_changed)
	
	add_to_group("UI")
	set_main_panel("looks","all");


func set_main_panel(panel: String,sub_panel: String):
	var found := _main_panel.find_child(panel)
	if not found:
		var scene = load("res://ui/panels/"+panel+"/"+panel+".tscn").instantiate().with(_library,_scene_manager)
		scene.name = panel
		
		_main_panel.add_child(scene)
	
	if _main_menu:
		_main_menu.set_selected_item(panel,sub_panel)
	
	for c : Control in _main_panel.get_children():
		if c.name == panel:
			if c.has_method("set_sub_panel"):
				c.set_sub_panel(sub_panel)
			if pointer_sprite:
				if pointer_sprite.get_parent():
					pointer_sprite.reparent(c)
				else:
					c.add_child(pointer_sprite)
			c.visible = true
		else:
			c.visible = false


func current_person_changed(scene_manager: SceneManager):
	if scene_manager:
		if scene_manager.current_person_id < 0:
			set_main_panel("looks","all");
		scene_manager.set_focus_camera("hip")


func item_dropped(type: String,source_filter: String,dest_filter: String,item_id: int):
	#prints("Item dropped:",type,source_filter if not source_filter.is_empty() else "-","->",dest_filter,item_id)
	if type == "cloth":
		if dest_filter == "":
			_library.Clothes_RemoveItemFromFilter(source_filter,item_id)
		else:
			_library.Clothes_AddItemToFilter(dest_filter,item_id)


func person_clicked(person_id: int):
	_scene_manager.select_person(person_id)


func floor_clicked(event_position: Vector3,_camera_position: Vector3):
	_scene_manager.walk_person_to(event_position)
