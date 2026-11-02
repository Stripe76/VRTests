extends PersonItems

func _init() -> void:
	super("res://ui/panels/clothes/controls/cloth_button.gd")


func _get_items(vam_actor: VAMActor) -> Array:
	return vam_actor.get_clothes()


func _remove_item(vam_actor: VAMActor,item_id: int):
	vam_actor.remove_cloth(item_id)


func _connect_signals(vam_actor: VAMActor):
	if not vam_actor.clothes_list_changed.is_connected(items_list_change):
		vam_actor.clothes_list_changed.connect(items_list_change)
