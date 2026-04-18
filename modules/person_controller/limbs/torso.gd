class_name PersonTorso extends Node

@export_range(-1,1) var rotate : float = 0:
	set(value):
		rotate = value
		update_pose()
	get:
		return rotate
@export_range(-1,1) var tilt : float = 0:
	set(value):
		tilt = value
		update_pose()
	get:
		return tilt
@export_range(-1,1) var slouch : float = 0:
	set(value):
		slouch = value
		update_pose()
	get:
		return slouch
@export_range(-1,1) var height : float = 0:
	set(value):
		height = value
		update_pose()
	get:
		return height

var _hips : JointController
var _pelvis : JointController
var _abdomen_1 : JointController
var _abdomen_2 : JointController
var _chest : JointController


func _init(limb_name: String,hip : JointController,pelvis : JointController,abdomen_1 : JointController,abdomen_2 : JointController,chest: JointController,parent: Node3D) -> void:
	name = limb_name
	parent.add_child(self)
	owner = parent.get_parent()
	
	_hips = hip
	_pelvis = pelvis
	_abdomen_1 = abdomen_1
	_abdomen_2 = abdomen_2
	_chest = chest


func update_pose():
	_hips.height = height
	
	_abdomen_1.pose_x = slouch
	_abdomen_2.pose_x = slouch
	_chest.pose_x = slouch
	
	_abdomen_1.pose_y = rotate
	_abdomen_2.pose_y = rotate
	_chest.pose_y = rotate
	
	_abdomen_1.pose_z = tilt
	_abdomen_2.pose_z = tilt
	_chest.pose_z = tilt
