extends PersonItems

func _init() -> void:
	super("res://ui/panels/hair/controls/hair_button.gd")


func _get_items(vam_actor: VAMActor) -> Array:
	return vam_actor.get_hairs()


func _remove_item(vam_actor: VAMActor,item_id: int):
	vam_actor.remove_hair(item_id)


func _connect_signals(vam_actor: VAMActor):
	if not vam_actor.hairs_list_changed.is_connected(items_list_change):
		vam_actor.hairs_list_changed.connect(items_list_change)
