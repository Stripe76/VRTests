@tool
class_name PersonMovements extends Node

@export_tool_button("Refresh","Reload") var refresh = reset_person_controller
@export var person_controller : PersonController:
	set(value):
		person_controller = value
		set_person_controller(person_controller)


func reset_person_controller():
	set_person_controller(person_controller)


func set_person_controller(person_controller: PersonController) -> void:
	if not person_controller:
		return
	for n : Node in person_controller.get_children():
		if n.name.ends_with("Arm"):
			for r in n.get_children():
				n.remove_child(r)
				r.free()
			for c : Node in $Arms.get_children():
				var copy = c.duplicate()
				n.add_child(copy)
				copy.owner = get_parent()
		
		if n.name.ends_with("Torso"):
			for r in n.get_children():
				n.remove_child(r)
				r.free()
			for c : Node in $Torso.get_children():
				var copy = c.duplicate()
				n.add_child(copy)
				copy.owner = get_parent()
	
		if n.name.ends_with("Leg"):
			for r in n.get_children():
				n.remove_child(r)
				r.free()
			for c : Node in $Legs.get_children():
				var copy = c.duplicate()
				n.add_child(copy)
				copy.owner = get_parent()
		
	for c : Node in get_children():
		if c.has_method("set_person_controller"):
			c.set_person_controller(person_controller)
