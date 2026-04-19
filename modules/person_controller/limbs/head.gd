class_name PersonHead extends Node

@export var pinned_on: bool = false:
	set(value):
		if ik:
			ik.active = value;
		pinned_on = value
	get:
		return pinned_on

@export_range(-1,1) var side : float = 0:
	set(value):
		side = value
		update_pose()
	get:
		return side
@export_range(-1,1) var front : float = 0:
	set(value):
		front = value
		update_pose()
	get:
		return front
@export_range(-1,1) var tilt : float = 0:
	set(value):
		tilt = value
		update_pose()
	get:
		return tilt

@export_group("Inverse kinematics")
@export_range(0,1) var ik_influence : float = 1:
	set(value):
		ik_influence = value
		if ik:
			ik.influence = ik_influence
	get:
		return ik_influence
@export_range(-1,1) var up_down: float:
	set(value):
		up_down = value
		if ik_target:
			ik_target.rotation.x = up_down * PI/5.0
	get:
		return up_down
@export_range(-1,1) var left_right: float:
	set(value):
		left_right = value
		if ik_target:
			ik_target.rotation.y = -left_right * PI/4.0
	get:
		return left_right

@export_group("IK Nodes")
@export var ik: SkeletonModifier3D
@export var ik_target : Node3D


var _head : JointController
var _neck : JointController

func _init(limb_name: String,head: JointController,neck: JointController,parent: Node3D) -> void:
	name = limb_name
	parent.add_child(self)
	owner = parent.get_parent()
	
	_head = head
	_neck = neck


func update_pose():
	_head.pose_x = front
	_neck.pose_x = front
	
	_head.pose_y = side
	_neck.pose_y = side
	
	_head.pose_z = tilt
	_neck.pose_z = tilt
