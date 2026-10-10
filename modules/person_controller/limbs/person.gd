class_name Person extends Node

@export var position : Vector3:
	set(value):
		position = value
		update_pose()
	get:
		return position

var _skeleton : Skeleton3D

func _init(node_name: String,skeleton: Skeleton3D,parent: Node3D) -> void:
	name = node_name
	parent.add_child(self)
	owner = parent.get_parent()

	_skeleton = skeleton


func update_pose():
	_skeleton.position = position


func look_at(target: Vector3):
	_skeleton.look_at(target.rotated(Vector3.UP,PI))
