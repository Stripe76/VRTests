extends ItemButton

func _get_icon_image(item_id: int) -> Texture2D:
	return _library.Hairs_GetPreviewImage(item_id)
