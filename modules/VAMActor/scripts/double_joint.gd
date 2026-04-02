class_name DoubleJoint
extends Resource

@export var invert_x : bool = false:
	set(value): 
		invert_x = value
		update_pose_x(pose_x)
		update_pose_y(pose_y)
		update_pose_z(pose_z)
@export var invert_y : bool = false:
	set(value): 
		invert_y = value
		update_pose_x(pose_x)
		update_pose_y(pose_y)
		update_pose_z(pose_z)
@export var invert_z : bool = false:
	set(value): 
		invert_z = value
		update_pose_x(pose_x)
		update_pose_y(pose_y)
		update_pose_z(pose_z)

@export_range(-1,1) var pose_x : float = 0:
	set(value):
		pose_x = value
		update_pose_x(pose_x)
	get: return pose_x
@export_range(-1,1) var base_x : float = 0:
	set(value):
		base_x = value
		update_base_x(base_x)
@export_range(0,1) var pose_x_min : float = 1:
	set(value):
		pose_x_min = value
		update_pose_x_min(pose_x_min)
@export_range(0,1) var pose_x_max : float = 1:
	set(value):
		pose_x_max = value
		update_pose_x_max(pose_x_max)
@export_range(-1,1) var pose_y : float = 0:
	set(value):
		pose_y = value
		update_pose_y(pose_y)
	get: return pose_y
@export_range(-1,1) var base_y : float = 0:
	set(value):
		base_y = value
		update_base_y(base_y)
@export_range(0,1) var pose_y_min : float = 1:
	set(value):
		pose_y_min = value
		update_pose_y_min(pose_y_min)
@export_range(0,1) var pose_y_max : float = 1:
	set(value):
		pose_y_max = value
		update_pose_y_max(pose_y_max)
@export_range(-1,1) var pose_z : float = 0:
	set(value):
		pose_z = value
		update_pose_z(pose_z)
	get: return pose_z
@export_range(-1,1) var base_z : float = 0:
	set(value):
		base_z = value
		update_base_z(base_z)
@export_range(0,1) var pose_z_min : float = 1:
	set(value):
		pose_z_min = value
		update_pose_z_min(pose_z_min)
@export_range(0,1) var pose_z_max : float = 1:
	set(value):
		pose_z_max = value
		update_pose_z_max(pose_z_max)

var first_joint : JointController
var second_joint : JointController

var x_inversion : float = -1
var y_inversion : float = -1
var z_inversion : float = -1

func _init(first: JointController,second: JointController,inversions: Array = []) -> void:
	first_joint = first
	second_joint = second
	if inversions.size() > 0:	x_inversion = inversions[0]
	if inversions.size() > 1:	y_inversion = inversions[1]
	if inversions.size() > 2:	z_inversion = inversions[2]
	
	
func update_pose_x(value: float):
	first_joint.pose_x = value
	if invert_x: second_joint.pose_x = -value * x_inversion
	else: second_joint.pose_x = value * x_inversion
func update_base_x(value: float):
	first_joint.base_x = value
	if x_inversion > 0:	second_joint.base_x = value
	else :	second_joint.base_x = -value
func update_pose_x_min(value: float):
	first_joint.pose_x_min = value
	if x_inversion > 0:	second_joint.pose_x_min = value
	else :	second_joint.pose_x_max = value
func update_pose_x_max(value: float):
	first_joint.pose_x_max = value
	if x_inversion > 0:	second_joint.pose_x_max = value
	else :	second_joint.pose_x_min = value


func update_pose_y(value: float):
	first_joint.pose_y = value
	if invert_y: second_joint.pose_y = -value * y_inversion
	else: second_joint.pose_y = value * y_inversion
func update_base_y(value: float):
	first_joint.base_y = value
	if y_inversion > 0:	second_joint.base_y = value
	else :	second_joint.base_y = -value
func update_pose_y_min(value: float):
	first_joint.pose_y_min = value
	if y_inversion > 0:	second_joint.pose_y_min = value
	else :	second_joint.pose_y_max = value
func update_pose_y_max(value: float):
	first_joint.pose_y_max = value
	if y_inversion > 0:	second_joint.pose_y_max = value
	else :	second_joint.pose_y_min = value


func update_pose_z(value: float):
	first_joint.pose_z = value
	if invert_z: second_joint.pose_z = -value * z_inversion
	else: second_joint.pose_z = value * z_inversion
func update_base_z(value: float):
	first_joint.base_z = value
	if z_inversion > 0:	second_joint.base_z = value
	else :	second_joint.base_z = -value
func update_pose_z_min(value: float):
	first_joint.pose_z_min = value
	if z_inversion > 0:	second_joint.pose_z_min = value
	else :	second_joint.pose_z_max = value
func update_pose_z_max(value: float):
	first_joint.pose_z_max = value
	if z_inversion > 0:	second_joint.pose_z_max = value
	else :	second_joint.pose_z_min = value
