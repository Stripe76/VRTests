extends ItemsSelection

func _init() -> void:
	super("res://ui/panels/looks/controls/look_button.gd")


func _get_count() -> int:
	return _library.Looks_GetCount()
