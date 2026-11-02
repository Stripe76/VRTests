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
	
	%AllLooks.set_library(_library)
	%AllLooks.item_selected.connect(_all_looks_item_selected)


func _all_looks_item_selected(item_id: int) -> void:
	if _scene_manager:
		_scene_manager.select_looks(item_id)
