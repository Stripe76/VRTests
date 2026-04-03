@tool
class_name CenterOfGravity
extends Node3D

@export_range(-1,1) var x : float:
	set(value):
		x = value
		update_cog()
	get:
		return x
@export_range(-1,1) var y : float:
	set(value):
		y = value
		update_cog()
	get:
		return y

var _skeleton : Skeleton3D

var mesh : MeshInstance3D
var left_leg : PersonLeg
var right_leg : PersonLeg


func _init(skeleton: Skeleton3D) -> void:
	_skeleton = skeleton


func _physics_process(delta: float) -> void:
	if _skeleton and mesh:
		var pos := get_cog()
		pos += _skeleton.position
		
		mesh.position.x = pos.x
		mesh.position.z = pos.y
		#print(pos)


func update_cog()-> void:
	var cog := get_cog()
	#var x_pos := x * get_half_width()
	#print(x_pos)
	if x > 0:
		left_leg.weight_on = false
		right_leg.weight_on = true
		
		right_leg.pinned_on = false
		#if not left_leg.pinned_on:
		#	left_leg.pinned_on = true
		#left_leg.ik.global_position = left_leg.foot_bone.global_position
		
		right_leg.hips_vertical = -x
		right_leg.lateral = x*.80
		right_leg.ankle = -x*.50
			
		#if x < 0.2:
		#	left_leg.ik_influence = x / 0.2
		#else:
		#	left_leg.ik_influence = 1.0
		#right_leg.ik_influence = 0
	if x < 0:
		left_leg.weight_on = true
		right_leg.weight_on = false
		
		left_leg.pinned_on = false
		#if not right_leg.pinned_on:
		#	right_leg.pinned_on = true
		#right_leg.ik.global_position = right_leg.foot_bone.global_position
		
		left_leg.hips_vertical = -x
		left_leg.lateral = x*.80
		left_leg.ankle = -x*.50
		
		#if x > -0.1:
		#	right_leg.ik_influence = x / -0.1
		#else:
		#	right_leg.ik_influence = 1.0
		#left_leg.ik_influence = 0
	pass


func get_cog() -> Vector3:
	var pos := _skeleton.get_bone_global_pose(Bones.PELVIS_BONE).origin
	#print(pos)
	
	return Vector3(pos.x,0,pos.z)

func get_half_width() -> float:
	var left := _skeleton.get_bone_global_pose(Bones.TOE_LEFT_BONE).origin
	var right := _skeleton.get_bone_global_pose(Bones.TOE_RIGHT_BONE).origin
	return abs(right.x-left.x) / 2
