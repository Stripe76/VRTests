extends Control

var _library : LibraryManager
var _scene_manager: SceneManager


func with(library: LibraryManager,scene_manager: SceneManager) -> Node:
	_library = library
	_scene_manager = scene_manager
	
	return self


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	%AllClothes.set_library(_library)
	%AllClothes.item_selected.connect(_all_clothes_item_selected)
	%PersonClothes.set_scene_manager(_scene_manager)


func _all_clothes_item_selected(item_id: int) -> void:
	if _scene_manager:
		_scene_manager.add_person_cloth(item_id)
