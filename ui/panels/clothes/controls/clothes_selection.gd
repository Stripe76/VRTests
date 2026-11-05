class_name ClothesSelection extends ItemsSelection

func _init() -> void:
	super("res://ui/panels/clothes/controls/cloth_button.gd")


func _get_count(filter: String) -> int:
	return _library.Clothes_GetCount(filter)


func _map_index_to_id(filter: String,index: int) -> int:
	return _library.Clothes_MapIndexToID(filter,index)
