extends ItemButton

func _get_icon_image(item_id: int) -> Texture2D:
	return _library.Looks_GetPreviewImage(item_id)
