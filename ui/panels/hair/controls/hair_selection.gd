class_name HairSelection extends ItemsSelection

func _init() -> void:
	super("res://ui/panels/hair/controls/hair_button.gd")


func _get_count(filter: String) -> int:
	return _library.Hairs_GetCount()
