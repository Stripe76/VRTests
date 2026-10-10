class_name JointController extends Resource

@export var limp_on : bool:
	set(value):
		limp_on = value
		
		set_limp(limp_on)
	get:
		return limp_on

@export_range(-1,1) var pose_x : float = 0:
	set(value):
		pose_x = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return pose_x
@export_range(-1,1) var pose_y : float = 0:
	set(value):
		pose_y = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return pose_y
@export_range(-1,1) var pose_z : float = 0:
	set(value):
		pose_z = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return pose_z
@export_range(-1,1) var height : float = 0:
	set(value):
		height = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return height

@export_range(0,4) var stiffness : float = 0:
	set(value):
		stiffness = value
		if _spring:
			_spring.set_stiffness(0,stiffness)
	get: 
		return stiffness

@export_group("Ranges")
@export_range(0,1) var x_min : float = 0:
	set(value):
		x_min = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return x_min
@export_range(0,1) var x_max : float = 0:
	set(value):
		x_max = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return x_max
@export_range(0,1) var y_min : float = 0:
	set(value):
		y_min = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return y_min
@export_range(0,1) var y_max : float = 0:
	set(value):
		y_max = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return y_max
@export_range(0,1) var z_min : float = 0:
	set(value):
		z_min = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return z_min
@export_range(0,1) var z_max : float = 0:
	set(value):
		z_max = value
		update_pose(pose_x,pose_y,pose_z,height)
	get: return z_max

var _bone : int
var _skeleton : Skeleton3D
var _base_position : Vector3

var _spring : SpringBoneSimulator3D
var _limp_stiffness : float


func _init(skeleton: Skeleton3D,bone: int,limits : Dictionary = {},spring : SpringBoneSimulator3D = null,limp_stiffness : float = 0) -> void:
	_bone = bone
	_skeleton = skeleton
	_base_position = skeleton.get_bone_pose_position(bone)
	
	_spring = spring
	_limp_stiffness = limp_stiffness
	
	if limits.has("x_min"):	x_min = limits["x_min"]
	if limits.has("x_max"):	x_max = limits["x_max"]
	if limits.has("y_min"):	y_min = limits["y_min"]
	if limits.has("y_max"):	y_max = limits["y_max"]
	if limits.has("z_min"):	z_min = limits["z_min"]
	if limits.has("z_max"):	z_max = limits["z_max"]


func reset_pose():
	pose_x = 0
	pose_y = 0
	pose_z = 0


func update_pose(x: float,y: float,z: float,h: float):
	if _skeleton:
		var new_x := update_rotation(x,x_min,x_max)
		var new_y := update_rotation(y,y_min,y_max)
		var new_z := update_rotation(z,z_min,z_max)
		
		_skeleton.set_bone_pose_position(_bone,_base_position+Vector3(0,h,0))
		_skeleton.set_bone_pose_rotation(_bone,Quaternion.from_euler(Vector3(new_x*PI,new_y*PI,new_z*PI)))


var _drag : float
var _gravity : float
var _stiffness : float
func set_limp(limp: bool):
	if _spring:
		if limp:
			_drag = _spring.get_drag(0)
			_gravity = _spring.get_gravity(0)
			_stiffness = _spring.get_stiffness(0)
			
			_spring.set_drag(0,0.1)
			_spring.set_gravity(0,1.0)
			_spring.set_stiffness(0,_limp_stiffness)
		else:
			_spring.set_drag(0,_drag)
			_spring.set_gravity(0,_gravity)
			_spring.set_stiffness(0,_stiffness)


static func update_rotation(to_set: float,pose_min: float,pose_max: float) -> float:
	if pose_max > pose_min:
		if to_set > 0:
			return to_set * pose_max
		else:
			return max( -pose_min,to_set * pose_max )
	else:
		if to_set > 0:
			return min( pose_max,to_set * pose_min )
		else:
			return to_set * pose_min
