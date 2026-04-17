class_name PersonLimb extends Node

signal weight_on_changed

@export var weight_on: bool = false:
	set(value):
		weight_on = value
		if weight_on:
			wo_position = ik_bone.global_position
		weight_on_changed.emit(self,weight_on)
	get:
		return weight_on
@export var pinned_on: bool = false:
	set(value):
		pinned_on = value
		if pinned_on:
			front = 0
			side = 0
			height = 0
			
			ik_position = ik_bone.global_position
			ik_target.global_position = ik_position
		if ik:
			ik.active = value;
	get:
		return pinned_on

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
@export_range(-0.5,0.5) var side: float:
	set(value):
		side = value
		ik_target.position.x = ik_position.x + side
@export_range(-1,1) var height: float:
	set(value):
		height = value
		ik_target.position.y = ik_position.y + height

@export_group("IK Nodes")
@export var ik: IKModifier3D
@export var ik_bone : Node3D
@export var ik_target : Node3D

var ik_bone_idx : int
var ik_position : Vector3
var wo_position : Vector3
