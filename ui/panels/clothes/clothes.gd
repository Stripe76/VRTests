extends Control

@onready var person_clothes: HBoxContainer = %PersonClothes
@onready var all_clothes: ClothesSelection = %AllClothes
@onready var filtered_clothes: ClothesSelection = %FilteredClothes

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
	
	all_clothes.set_library(_library)
	all_clothes.item_selected.connect(_all_clothes_item_selected)
	
	filtered_clothes.set_library(_library)
	filtered_clothes.item_selected.connect(_all_clothes_item_selected)
	
	person_clothes.set_scene_manager(_scene_manager)


func _all_clothes_item_selected(item_id: int) -> void:
	if _scene_manager:
		_scene_manager.add_person_cloth(item_id)


func set_sub_panel(sub_panel: String):
	if sub_panel.is_empty() or sub_panel.begins_with("all_"):
		all_clothes.visible = true
		filtered_clothes.visible = false
	else:
		filtered_clothes.items_filter = sub_panel
		filtered_clothes.visible = true
		all_clothes.visible = false
