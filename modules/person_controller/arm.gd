class_name PersonArm extends PersonLimb

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

var _collar : JointController
var _shoulder : JointController
var _elbow : JointController

func _init(limb_name: String,collar : JointController,shoulder : JointController,elbow : JointController,parent: Node3D) -> void:
	name = limb_name
	parent.add_child(self)
	owner = parent.get_parent()
	
	_collar = collar
	_shoulder = shoulder
	_elbow = elbow


func update_pose():
	_collar.pose_y = horizontal
	#_collar.pose_z = (vertical + twist) / 2
	_collar.pose_z = vertical
	
	_shoulder.pose_x = twist
	_shoulder.pose_y = horizontal
	_shoulder.pose_z = vertical
	
	_elbow.pose_y = straight
