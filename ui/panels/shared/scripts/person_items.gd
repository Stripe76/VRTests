class_name PersonItems extends Control

var _scene_manager : SceneManager
var _button_script : Script


func _init(script: String):
	_button_script = load(script)


func _get_items(_vam_actor: VAMActor) -> Array:
	return []


func _remove_item(_vam_actor: VAMActor,_item_id: int):
	pass


func _connect_signals(_vam_actor: VAMActor):
	pass


func set_scene_manager(scene_manager: SceneManager):
	_scene_manager = scene_manager
	_scene_manager.current_person_changed.connect(current_person_changed)
	
	current_person_changed(_scene_manager)


func current_person_changed(scene_manager: SceneManager):
	var vam_actor := scene_manager.current_person
	if vam_actor:
		var items := _get_items(vam_actor)
		var children := get_children( )
		
		var child_count := get_child_count()
		var item_count := items.size()
		for i in min(child_count,item_count):
			var button : ItemButton = children[i]
			var item = items[i]
			button.change_item_id(i,item.id)
			button.theme_type_variation = "SelectedButton" if item.visible else ""
		if child_count > item_count:
			for i in child_count - item_count:
				remove_child(children[item_count+i])
		if child_count < item_count:
			for i in item_count - child_count:
				var item = items[child_count+i]
				var button : ItemButton = _button_script.new(scene_manager.get_library(),i,i,"",Vector2(100,100))
				button.theme_type_variation = "SelectedButton" if item.visible else ""
				button.change_item_id(i,item.id)
				button.button_selected.connect(item_selected)
				button.button_middle_selected.connect(item_middle_selected)
				add_child(button)
		_connect_signals(vam_actor)


func items_list_change(_vam_actor:VAMActor):
	current_person_changed(_scene_manager)


func item_selected(button: ItemButton,item_id: int):
	var vam_actor := _scene_manager.current_person
	if vam_actor:
		var items := _get_items(vam_actor)
		for i in items:
			if i.id == item_id:
				i.visible = not i.visible
				button.theme_type_variation = "SelectedButton" if i.visible  else ""


func item_middle_selected(_button: ItemButton,item_id: int):
	var vam_actor := _scene_manager.current_person
	if vam_actor:
		_remove_item(vam_actor,item_id)
