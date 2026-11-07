class_name WorldScene extends Node3D

@onready var _persons := $Persons


func add_person(person: Node3D):
	_persons.add_child(person)


func get_traverse_path(origin: Vector3,destination: Vector3) -> PackedVector3Array:
	var room := $Environment/Minimalist
	if room:
		var navigation := room.find_child("Navigation")
		if navigation:
			return navigation.get_traverse_path(origin,destination)
	return PackedVector3Array();
