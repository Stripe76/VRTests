@tool
class_name PersonLimb extends Node

signal root_on_changed

@export var ik_on: bool = false:
	set(value):
		#prints("ik_on",value)
		if value:
			#ik_influence = 0
			
			ik_position = ik_bone.position
			#local_target.position = ik_position
			global_target.global_position = local_target.to_global(ik_position-local_target.position)
		if ik:
			ik.active = value;
			
		ik_on = value
	get:
		return ik_on
@export var root_on: bool = false:
	set(value):
		#prints("root_on",root_on)
		root_on = value
		if root_on:
			ro_position = ik_bone.global_position
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
		global_target.global_position = local_target.to_global(Vector3(side,height,value))
	get:
		return local_target.to_local(global_target.global_position).z
@export_range(-0.5,0.5) var side: float:
	set(value):
		global_target.global_position = local_target.to_global(Vector3(value,height,front))
	get:
		return local_target.to_local(global_target.global_position).x
@export_range(0,1) var height: float:
	set(value):
		global_target.global_position = local_target.to_global(Vector3(side,value,front))
	get:
		return local_target.to_local(global_target.global_position).y

@export_group("IK Nodes")
@export var ik: IKModifier3D
@export var ik_bone : Node3D
@export var local_target : Node3D
@export var global_target : Node3D

var ik_bone_idx : int
var ik_position : Vector3
var ro_position : Vector3
var ro_y_rotation : float
