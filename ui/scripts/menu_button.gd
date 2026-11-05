class_name MenuItemButton extends Button

@export var drag_data : String = ""
@export var drag_filter : String = ""

signal drop_request

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and data.has("type") and data["type"] == drag_data:
		drop_request.emit()
		return true
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary and data.has("type") and data["type"] == drag_data:
		get_tree().call_group("UI","item_dropped",data["type"],data["filter"],drag_filter,data["item_id"])
