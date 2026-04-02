#@tool
class_name JointController
extends Resource

@export_group("Pose position")
@export_range(-1,1) var pose_x : float = 0:
	set(value):
		pose_x = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_x
@export_range(-1,1) var pose_y : float = 0:
	set(value):
		pose_y = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_y
@export_range(-1,1) var pose_z : float = 0:
	set(value):
		pose_z = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_z

@export_group("Pose ranges")
@export_range(0,1) var pose_x_min : float = 1:
	set(value):
		pose_x_min = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_x_min
@export_range(0,1) var pose_x_max : float = 1:
	set(value):
		pose_x_max = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_x_max
@export_range(0,1) var pose_y_min : float = 1:
	set(value):
		pose_y_min = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_y_min
@export_range(0,1) var pose_y_max : float = 1:
	set(value):
		pose_y_max = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_y_max
@export_range(0,1) var pose_z_min : float = 1:
	set(value):
		pose_z_min = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_z_min
@export_range(0,1) var pose_z_max : float = 1:
	set(value):
		pose_z_max = value
		update_pose(pose_x,pose_y,pose_z)
	get: return pose_z_max

@export_group("Base position")
@export_range(-1,1) var base_x : float = 0:
	set(value):
		base_x = value
		update_base(base_x,base_y,base_z)
	get: return base_x
@export_range(-1,1) var base_y : float = 0:
	set(value):
		base_y = value
		update_base(base_x,base_y,base_z)
	get: return base_y
@export_range(-1,1) var base_z : float = 0:
	set(value):
		base_z = value
		update_pose(0,0,pose_z)
	get: return base_z

#@export_range(0,1) 
@export_range(0,1) var base_x_min : float = 0:
	set(value):
		base_x_min = value
		update_pose(pose_x,pose_y,pose_z)
	get: return base_x_min
@export_range(0,1) var base_x_max : float = 0:
	set(value):
		base_x_max = value
		update_pose(pose_x,pose_y,pose_z)
	get: return base_x_max
@export_range(0,1) var base_y_min : float = 0:
	set(value):
		base_y_min = value
		update_pose(pose_x,pose_y,pose_z)
	get: return base_y_min
@export_range(0,1) var base_y_max : float = 0:
	set(value):
		base_y_max = value
		update_pose(pose_x,pose_y,pose_z)
	get: return base_y_max
@export_range(0,1) var base_z_min : float = 0:
	set(value):
		base_z_min = value
		update_pose(pose_x,pose_y,pose_z)
	get: return base_z_min
@export_range(0,1) var base_z_max : float = 0:
	set(value):
		base_z_max = value
		update_pose(pose_x,pose_y,pose_z)
	get: return base_z_max

var bone : int
var skeleton : Skeleton3D


func _init(skeleton: Skeleton3D,bone: int,limits : Dictionary = {}) -> void:
	self.bone = bone
	self.skeleton = skeleton
	if limits.has("x_min"):	base_x_min = limits["x_min"]
	if limits.has("x_max"):	base_x_max = limits["x_max"]
	if limits.has("y_min"):	base_y_min = limits["y_min"]
	if limits.has("y_max"):	base_y_max = limits["y_max"]
	if limits.has("z_min"):	base_z_min = limits["z_min"]
	if limits.has("z_max"):	base_z_max = limits["z_max"]


func reset_pose():
	base_x = 0
	base_y = 0
	base_z = 0
	
	pose_x_min = 1
	pose_x_max = 1
	pose_y_min = 1
	pose_y_max = 1
	pose_z_min = 1
	pose_z_max = 1
	
	pose_x = 0
	pose_y = 0
	pose_z = 0


func update_base(x: float,y: float,z: float):
	if skeleton:
		var new_z : float = 0
		if z > 0:
			new_z += z * base_z_max
		elif z < 0:
			new_z += z * base_z_min
	
		update_pose(0,0,pose_z)
		#skeleton.set_bone_pose_rotation(bone,Quaternion.from_euler(Vector3(base_x*PI,base_y*PI,new_z*PI)))


func update_pose(x: float,y: float,z: float):
	if skeleton:
		var new_x := update_rotation(x,base_x,base_x_min,base_x_max,pose_x_min,pose_x_max)
		var new_y := update_rotation(y,base_y,base_y_min,base_y_max,pose_y_min,pose_y_max)
		var new_z := update_rotation(z,base_z,base_z_min,base_z_max,pose_z_min,pose_z_max)
		
		skeleton.set_bone_pose_rotation(bone,Quaternion.from_euler(Vector3(new_x*PI,new_y*PI,new_z*PI)))


static func update_rotation(to_set: float,base: float,base_min: float,base_max: float,pose_min: float,pose_max: float) -> float:
	var value := base
	if to_set > 0:
		value += to_set * pose_max * (1-base)
	elif to_set < 0:
		value += to_set * pose_min * (base+1)
	if value > 0:
		value *= base_max
	elif value < 0:
		value *= base_min
	return value
