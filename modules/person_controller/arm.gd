class_name PersonArm extends Node

@export var pinned_on: bool = false:
	set(value):
		pinned_on = value
		if pinned_on:
			ik_position = ik_bone.global_position
			ik_target.global_position = ik_position
		if ik:
			ik.active = value;
	get:
		return pinned_on

@export_range(-1,1) var straight : float = 0:
	set(value):
		straight = value
		update_pose()
	get:
		return straight
@export_range(-1,1) var horizontal : float = 0:
	set(value):
		horizontal = value
		update_pose()
	get:
		return horizontal
@export_range(-1,1) var vertical : float = 0:
	set(value):
		vertical = value
		update_pose()
	get:
		return vertical
@export_range(-1,1) var twist : float = 0:
	set(value):
		twist = value
		update_pose()
	get:
		return twist
@export_range(-1,1) var wrist : float = 0:
	set(value):
		wrist = value
		update_pose()
	get:
		return wrist

@export_range(0,1) var ik_influence : float = 0:
	set(value):
		ik_influence = value
		if ik:
			ik.influence = ik_influence
	get:
		return ik_influence

@export_group("Inverse kinematics")
@export var ik: IKModifier3D
@export var ik_target : Node3D
@export var ik_bone : VAMPhysicalBone3D

var _collar : JointController
var _shoulder : JointController
var _elbow : JointController

var ik_position : Vector3

var i := true
func _init(name: String,collar : JointController,shoulder : JointController,elbow : JointController,parent: Node3D) -> void:
	self.name = name
	parent.add_child(self)
	self.owner = parent.get_parent()
	
	_collar = collar
	_shoulder = shoulder
	_elbow = elbow
	
	horizontal = _shoulder.pose_y
	vertical = _shoulder.pose_z
	twist = _shoulder.pose_x
	
	straight = _elbow.pose_y
	
	i = false


func update_pose():
	if i: return
	
	_collar.pose_y = horizontal
	#_collar.pose_z = (vertical + twist) / 2
	_collar.pose_z = vertical
	
	_shoulder.pose_x = twist
	_shoulder.pose_y = horizontal
	_shoulder.pose_z = vertical
	
	_elbow.pose_y = straight
