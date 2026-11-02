extends Control

var _scene_manager : SceneManager
var _cloth_button_script : Script = load("res://ui/panels/clothes/controls/cloth_button.gd")


func set_scene_manager(scene_manager: SceneManager):
	_scene_manager = scene_manager
	_scene_manager.current_person_changed.connect(current_person_changed)
	
	current_person_changed(_scene_manager)


func current_person_changed(scene_manager: SceneManager):
	var vam_actor := scene_manager.current_person
	if vam_actor:
		var clothes := vam_actor.get_clothes()
		var children := get_children( )
		
		var count := get_child_count()
		var items := clothes.size()
		for i in min(count,items):
			var button : ItemButton = children[i]
			var cloth = clothes[i]
			button.change_item_id(cloth.id)
			button.theme_type_variation = "SelectedButton" if cloth.visible else ""
		if count > items:
			for i in count - items:
				remove_child(children[items+i])
		if count < items:
			for i in items - count:
				var cloth = clothes[count+i]
				var button : ItemButton = _cloth_button_script.new(scene_manager.get_library(),i,Vector2(100,100))
				button.theme_type_variation = "SelectedButton" if cloth.visible else ""
				button.change_item_id(cloth.id)
				button.button_selected.connect(cloth_selected)
				button.button_middle_selected.connect(cloth_middle_selected)
				add_child(button)
		if not vam_actor.clothes_list_changed.is_connected(clothes_list_change):
			vam_actor.clothes_list_changed.connect(clothes_list_change)


func clothes_list_change(vam_actor:VAMActor):
	current_person_changed(_scene_manager)


func cloth_selected(button: ItemButton,cloth_id: int):
	var vam_actor := _scene_manager.current_person
	if vam_actor:
		var clothes := vam_actor.get_clothes()
		for c in clothes:
			if c.id == cloth_id:
				c.visible = not c.visible
				button.theme_type_variation = "SelectedButton" if c.visible  else ""


func cloth_middle_selected(button: ItemButton,cloth_id: int):
	var vam_actor := _scene_manager.current_person
	if vam_actor:
		vam_actor.remove_cloth(cloth_id)
