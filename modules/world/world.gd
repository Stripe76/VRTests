class_name WorldScene extends Node3D

@onready var _persons := $Persons


func add_person(person: Node3D):
	_persons.add_child(person)
	
	#await get_tree().get_frame()
	#
	#person.position = pos
	##var tween = get_tree().create_tween()
	##tween.tween_property(person,"position",pos,1.0)


func toggle_wall_visibility(wall: String,wall_visible: bool):
	for room in $Environment.get_children():
		if room.has_method("toggle_wall_visibility"):
			room.toggle_wall_visibility(wall,wall_visible)
