extends Control

var _scene_manager : SceneManager
var _person_button : PackedScene = load("res://ui/panels/person_button.tscn")

func set_scene_manager(scene_manager: SceneManager):
	_scene_manager = scene_manager
	_scene_manager.persons_list_changed.connect(persons_list_changed)
	_scene_manager.current_person_changed.connect(current_person_changed)
	
	persons_list_changed(_scene_manager,_scene_manager._persons)


func current_person_changed(scene_manager: SceneManager):
	var i := 0
	var selected := scene_manager.current_person
	for button : PersonButton in get_children():
		if i == selected or (selected < 0 and i == get_child_count()-1 ):
			button.theme_type_variation = "SelectedButton"
		else:
			button.theme_type_variation = ""
		i += 1


func persons_list_changed(scene_manager: SceneManager,persons: Array):
	for c in get_children():
		c.queue_free()
	
	if persons:
		for i in persons.size():
			var person : VAMActor = persons[i]
			var button : PersonButton = _person_button.instantiate().with_data(scene_manager.get_library(),i,person.get_looks_id())
			button.theme_type_variation = "SelectedButton" if i == scene_manager.current_person else ""
			
			add_child(button)
	var add_button : PersonButton = _person_button.instantiate().with_data(scene_manager.get_library(),-1,-1)
	add_button.theme_type_variation = "SelectedButton" if scene_manager.current_person < 0 else ""
	
	add_child(add_button)
