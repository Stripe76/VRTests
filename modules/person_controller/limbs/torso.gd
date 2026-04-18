class_name PersonTorso extends Node

@export_range(-1,1) var height : float = 0:
	set(value):
		height = value
		update_pose()
	get:
		return height

var _hips : JointController

func _init(limb_name: String,hip : JointController,parent: Node3D) -> void:
	name = limb_name
	parent.add_child(self)
	owner = parent.get_parent()
	
	_hips = hip


func update_pose():
	_hips.height = height
