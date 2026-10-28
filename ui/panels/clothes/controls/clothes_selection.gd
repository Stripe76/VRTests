class_name ClothesSelection extends ItemsSelection

func _init() -> void:
	super("res://ui/panels/clothes/controls/cloth_button.gd")


func _get_count() -> int:
	return _library.Clothes_GetCount()
