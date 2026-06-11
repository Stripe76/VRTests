class_name PersonLeg extends PersonLimb

@export_range(-1,1) var hips_vertical : float = 0:
	set(value):
		hips_vertical = value
		update_pose()
	get:
		return hips_vertical
@export_range(-1,1) var hips_horizontal : float = 0:
	set(value):
		hips_horizontal = value
		update_pose()
	get:
		return hips_horizontal
@export_range(-1,1) var bend : float = 0:
	set(value):
		bend = value
		update_pose()
	get:
		return bend
@export_range(-1,1) var frontal : float = 0:
	set(value):
		frontal = value
		update_pose()
	get:
		return frontal
@export_range(-1,1) var lateral : float = 0:
	set(value):
		lateral = value
		update_pose()
	get:
		return lateral
@export_range(-1,1) var twist : float = 0:
	set(value):
		twist = value
		update_pose()
	get:
		return twist
@export_range(-1,1) var ankle_side : float = 0:
	set(value):
		ankle_side = value
		update_pose()
	get:
		return ankle_side
@export_range(-1,1) var ankle_front : float = 0:
	
	set(value):
		ankle_front = value
		update_pose()
	get:
		return ankle_front

@export_group("Multipliers")
@export_range(0,1) var hips_vertical_min : float = 1:
	set(value):
		hips_vertical_min = value
		update_pose()
	get:
		return hips_vertical_min
@export_range(0,1) var hips_vertical_max : float = 1:
	set(value):
		hips_vertical_max = value
		update_pose()
	get:
		return hips_vertical_max
@export_range(0,1) var hips_horizontal_min : float = 1:
	set(value):
		hips_horizontal_min = value
		update_pose()
	get:
		return hips_horizontal_min
@export_range(0,1) var hips_horizontal_max : float = 1:
	set(value):
		hips_horizontal_max = value
		update_pose()
	get:
		return hips_horizontal_max
@export_range(0,1) var frontal_min : float = 1:
	set(value):
		frontal_min = value
		update_pose()
	get:
		return frontal_min
@export_range(0,1) var frontal_max : float = 1:
	set(value):
		frontal_max = value
		update_pose()
	get:
		return frontal_max
@export_range(0,1) var bend_min : float = 1:
	set(value):
		bend_min = value
		update_pose()
	get:
		return bend_min
@export_range(0,1) var bend_max : float = 1:
	set(value):
		bend_max = value
		update_pose()
	get:
		return bend_max
@export_range(0,1) var lateral_min : float = 1:
	set(value):
		lateral_min = value
		update_pose()
	get:
		return lateral_min
@export_range(0,1) var lateral_max : float = 1:
	set(value):
		lateral_max = value
		update_pose()
	get:
		return lateral_max
@export_range(0,1) var twist_min : float = 1:
	set(value):
		twist_min = value
		update_pose()
	get:
		return twist_min
@export_range(0,1) var twist_max : float = 1:
	set(value):
		twist_max = value
		update_pose()
	get:
		return twist_max

var _hip : JointController
var _pelvis : JointController
var _knee : JointController
var _ankle : JointController

func _init(limb_name: String,hip : JointController,pelvis : JointController,knee : JointController,ankle : JointController,parent: Node3D) -> void:
	name = limb_name
	parent.add_child(self)
	owner = parent.get_parent()
	
	_hip = hip
	_pelvis = pelvis
	_knee = knee
	_ankle = ankle


func update_pose():
	_hip.pose_z = hips_vertical * (hips_vertical_max if hips_vertical > 0 else hips_vertical_min)
	_hip.pose_y = hips_horizontal * (hips_horizontal_max if hips_horizontal > 0 else hips_horizontal_min)
	
	_pelvis.pose_x = -frontal * (frontal_max if frontal > 0 else frontal_min)
	_pelvis.pose_y = twist * (twist_max if twist > 0 else twist_min)
	_pelvis.pose_z = lateral * (lateral_max if lateral > 0 else lateral_min)
	
	_knee.pose_x = bend * (bend_max if bend > 0 else bend_min)
	
	_ankle.pose_z = ankle_side
	_ankle.pose_x = ankle_front
