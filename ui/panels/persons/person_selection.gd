extends Control

@export var show_add_button : bool:
	set(value):
		_add_button.visible = value
		$Placeholder.visible = not value
	get:
		return _add_button.visible

@onready var items := $Items

var _scene_manager : SceneManager
var _button_script : Script = load("res://ui/panels/persons/person_button.gd")

var _add_button : PersonButton


func _ready() -> void:
	persons_list_changed(_scene_manager,_scene_manager._persons)


func set_scene_manager(scene_manager: SceneManager):
	_scene_manager = scene_manager
	_scene_manager.persons_list_changed.connect(persons_list_changed)
	_scene_manager.current_person_changed.connect(current_person_changed)


func current_person_changed(scene_manager: SceneManager):
	var i := 0
	var selected := scene_manager.current_person_id
	for button : PersonButton in items.get_children():
		if i == selected or (selected < 0 and i == items.get_child_count()-1 ):
			button.is_selected = true
		else:
			button.is_selected = false
		i += 1


func persons_list_changed(scene_manager: SceneManager,persons: Array):
	for c in items.get_children():
		c.queue_free()
	
	if persons:
		for i in persons.size():
			var person : VAMActor = persons[i]
			var button : PersonButton = _button_script.new().with_data(scene_manager.get_library(),i,person.get_look_id())
			button.is_selected = i == scene_manager.current_person_id
			button.button_selected.connect(button_selected)
			button.button_middle_selected.connect(button_middle_selected)
			
			items.add_child(button)
	_add_button = _button_script.new().with_data(scene_manager.get_library(),-1,-1)
	_add_button.is_selected = scene_manager.current_person_id < 0
	_add_button.button_selected.connect(button_selected)
	
	items.add_child(_add_button)


func button_selected(_button: PersonButton,personID: int):
	get_tree().call_group("Scene","select_person",personID)


func button_middle_selected(_button: PersonButton,personID: int):
	get_tree().call_group("Scene","remove_person",personID)
