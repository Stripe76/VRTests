extends ItemButton

func _get_drag_info():
	return {"type":"cloth","filter":_item_filter,"item_id":_item_id}


func _get_icon_image(item_id: int) -> Texture2D:
	return _library.Clothes_GetPreviewImage(item_id)
