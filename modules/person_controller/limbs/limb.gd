class_name PersonLimb extends Node

signal root_on_changed

@export var ik_on: bool = false:
	set(value):
		if value and ik_on != value:
			front = 0
			side = 0
			height = 0
			
			ik_position = ik_bone.position
			ik_target.global_position = ik_position
		if ik:
			ik.active = value;
		ik_on = value
	get:
		return ik_on
@export var root_on: bool = false:
	set(value):
		root_on = value
		prints("root_on",root_on)
		if root_on:
			wo_position = ik_bone.global_position
		root_on_changed.emit(self,root_on)
	get:
		return root_on

@export_group("Inverse kinematics")
@export_range(0,1) var ik_influence : float = 1:
	set(value):
		ik_influence = value
		if ik:
			ik.influence = ik_influence
	get:
		return ik_influence
@export_range(-1,1) var front: float:
	set(value):
		front = value
		ik_target.position.z = ik_position.z + front
	get:
		return front
@export_range(-0.5,0.5) var side: float:
	set(value):
		side = value
		ik_target.position.x = ik_position.x + side
	get:
		return side
@export_range(-1,1) var height: float:
	set(value):
		height = value
		ik_target.position.y = ik_position.y + height
	get:
		return height

@export_group("IK Nodes")
@export var ik: IKModifier3D
@export var ik_bone : Node3D
@export var ik_target : Node3D

var ik_bone_idx : int
var ik_position : Vector3
var wo_position : Vector3
var wo_rotation : Vector3
