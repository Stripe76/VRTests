class_name PersonHead extends Node

@export var pinned_on: bool = false:
	set(value):
		if ik_head:
			ik_head.active = value;
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

@export_group("Eyes")
@export var eyes_pinned_on: bool = false:
	set(value):
		if ik_left_eye:
			ik_left_eye.active = value;
		if ik_right_eye:
			ik_right_eye.active = value;
		eyes_pinned_on = value
	get:
		return eyes_pinned_on
@export_range(-1,1) var eyes_left_right : float = 0:
	set(value):
		eyes_left_right = value
		update_eyes_pose()
	get:
		return eyes_left_right
@export_range(-1,1) var eyes_up_down : float = 0:
	set(value):
		eyes_up_down = value
		update_eyes_pose()
	get:
		return eyes_up_down

@export_group("Inverse kinematics")
@export_range(0,1) var ik_influence : float = 1:
	set(value):
		ik_influence = value
		if ik_head:
			ik_head.influence = ik_influence
	get:
		return ik_influence
@export_range(-1,1) var up_down: float:
	set(value):
		up_down = value
		if ik_target_head:
			ik_target_head.rotation.x = up_down * PI/5.0
	get:
		return up_down
@export_range(-1,1) var left_right: float:
	set(value):
		left_right = value
		if ik_target_head:
			ik_target_head.rotation.y = -left_right * PI/4.0
	get:
		return left_right

@export_group("IK Nodes")
@export var ik_head: SkeletonModifier3D
@export var ik_target_head : Node3D
@export var ik_left_eye: SkeletonModifier3D
@export var ik_right_eye: SkeletonModifier3D
@export var ik_target_eyes : Node3D

var _head : JointController
var _neck : JointController
var _left_eye : JointController
var _right_eye : JointController


func _init(limb_name: String,head: JointController,neck: JointController,left_eye : JointController,right_eye : JointController,parent: Node3D) -> void:
	name = limb_name
	parent.add_child(self)
	owner = parent.get_parent()
	
	_head = head
	_neck = neck
	_left_eye = left_eye
	_right_eye = right_eye


func update_pose():
	_head.pose_x = front
	_neck.pose_x = front
	
	_head.pose_y = side
	_neck.pose_y = side
	
	_head.pose_z = tilt
	_neck.pose_z = tilt


func update_eyes_pose():
	_left_eye.pose_x = eyes_up_down
	_left_eye.pose_y = -eyes_left_right
	
	_right_eye.pose_x = eyes_up_down
	_right_eye.pose_y = -eyes_left_right
