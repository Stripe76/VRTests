extends Control

var _library : LibraryManager
var _scene_manager: SceneManager
var _main_container : Control


func with(library: LibraryManager,scene_manager: SceneManager,main: Control) -> Node:
	_library = library
	_scene_manager = scene_manager
	_main_container = main
	
	return self


func _ready() -> void:
	if _main_container:
		reparent(_main_container)
		set_anchors_preset(Control.PRESET_FULL_RECT)
		
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		
		$AllClothes.set_library(_library)


func _all_clothes_item_selected(item_id: int) -> void:
	prints("Cloth selected:",item_id)
	if _scene_manager:
		_scene_manager.set_person_cloth(item_id)
