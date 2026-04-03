@tool
class_name PersonMovements
extends Node

@export var person_controller : PersonController:
	set(value):
		person_controller = value
		set_person_controller(person_controller)
		

func set_person_controller(person_controller: PersonController) -> void:
	if not person_controller:
		return
	for n : Node in person_controller.get_children():
		if n.name.ends_with("Leg"):
			for c : Node in $Legs.get_children():
				for r in n.get_children():
					n.remove_child(r)
					r.queue_free()
				
				var copy = c.duplicate()
				n.add_child(copy)
				copy.owner = get_parent()
			pass
