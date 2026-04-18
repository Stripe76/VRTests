@tool
class_name PersonController extends Node3D

@export_tool_button("Reset","Reload") var reset_action = reset_pose
	
@export_group("Left arm")
@export var left_collar : JointController
@export var left_shoulder : JointController
@export var left_elbow : JointController
@export_group("Right arm")
@export var right_collar : JointController
@export var right_shoulder : JointController
@export var right_elbow : JointController
@export_group("Both arms")
@export var both_collars : DoubleJoint
@export var both_shoulders : DoubleJoint
@export var both_elbows : DoubleJoint

@export_group("Torso")
@export var hips : JointController
@export var pelvis : JointController
@export var abdomen : JointController
@export var neck : JointController

@export_group("Left leg")
@export var left_hip : JointController
@export var left_knee : JointController
@export var left_ankle : JointController
@export_group("Right leg")
@export var right_hip : JointController
@export var right_knee : JointController
@export var right_ankle : JointController
@export_group("Both legs")
@export var both_hips : DoubleJoint
@export var both_knees : DoubleJoint
@export var both_ankles : DoubleJoint

@export_group("Hands")
@export var left_index : JointController

@export_group("Skeletons")
@export var _skeleton : Skeleton3D

var current_weight_on : PersonLimb

var _left_arm: PersonArm
var _right_arm: PersonArm

var _left_leg: PersonLeg
var _right_leg: PersonLeg


func _init(skeleton: Skeleton3D) -> void:
	print("--- PersonController._init")
	_skeleton = skeleton
	if _skeleton:
		#_skeleton.add_child(self)
		#self.owner = _skeleton
		
		#_skeleton_pose = duplicate_skeleton(parent,skeleton,"SkeletonPose")
		#_skeleton_springs = duplicate_skeleton(parent,skeleton,"SkeletonSprings")
		
		_skeleton.skeleton_updated.connect(_on_skeleton_updated)
		
		create_joints(_skeleton)
		create_springs(_skeleton)


var _editor_owner
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_editor_owner = owner
			owner = null
		NOTIFICATION_EDITOR_POST_SAVE:
			owner = _editor_owner


func _physics_process(_delta: float) -> void:
	#update_weight_on()
	pass


func _on_skeleton_updated():
	update_weight_on()


var _skeleton_offset := Vector3()
func update_weight_on(apply : bool = true) -> Vector3:
	if _skeleton and current_weight_on:
		#var delta : Vector3 = current_weight_on.wo_position - current_weight_on.ik_bone.global_position
		var delta : Vector3 = current_weight_on.wo_position - _skeleton.get_bone_global_pose(current_weight_on.ik_bone_idx).origin
		
		if apply:
			delta.x = 0
			delta.z = 0
			_skeleton.position = _skeleton_offset + delta
		return delta
	return Vector3()


func update_position(new_weight_on: int)-> int:
	if _skeleton:
		var parent : Node3D = _skeleton.get_parent()
		if parent:
			var position1 := update_weight_on(false)
			#print(position1)
	
			var position2 := update_weight_on(false)
			#print(position2)
	
			var posDelta := Vector3()
			posDelta.x = position1.x - position2.x
			posDelta.y = position1.y - position2.y
			posDelta.z = position1.z - position2.z
			#position.z = - position2.z*2
			#parent.position += posDelta
			#_skeleton_offset += posDelta
			#print(posDelta)
			
			#b = false
	return new_weight_on


func reset_pose():
	current_weight_on = null
	
	if _skeleton:
		_skeleton.position = Vector3()
		_skeleton.get_parent().position = Vector3()
	
	left_collar.reset_pose()
	right_collar.reset_pose()
	left_shoulder.reset_pose()
	right_shoulder.reset_pose()
	left_elbow.reset_pose()
	right_elbow.reset_pose()
	hips.reset_pose()
	pelvis.reset_pose()
	abdomen.reset_pose()
	neck.reset_pose()	
	left_hip.reset_pose()
	right_hip.reset_pose()
	left_knee.reset_pose()
	right_knee.reset_pose()
	left_ankle.reset_pose()
	right_ankle.reset_pose()
	
	_left_arm.pinned_on = false
	_right_arm.pinned_on = false
	_left_leg.pinned_on = false
	_right_leg.pinned_on = false


func initialize(parent: Node3D,skeleton: Skeleton3D) -> void:
	create_controllers( )
	create_collisions(parent,skeleton)
	create_center_of_gravity(_skeleton,parent)
	create_iks(_skeleton,parent)
	
	reset_pose()


func weight_on_changed(limb: PersonLimb,weight_on: bool):
	if weight_on:
		if current_weight_on:
			current_weight_on.weight_on = false
		current_weight_on = limb
	elif limb == current_weight_on:
		current_weight_on = null


func create_joints(skeleton: Skeleton3D) -> void:
		left_collar = JointController.new(skeleton,Bones.COLLAR_LEFT_BONE,{"x_min":0.1,"x_max":0.05,"y_min":0.15,"y_max":0.05,"z_min":0.053,"z_max":0.11})
		right_collar = JointController.new(skeleton,Bones.COLLAR_RIGHT_BONE,{"x_min":0.05,"x_max":0.1,"y_min":0.05,"y_max":0.15,"z_min":0.11,"z_max":0.053})
		left_shoulder = JointController.new(skeleton,Bones.SHOULDER_LEFT_BONE,{"x_min":0.3,"x_max":0.2,"y_min":0.5,"y_max":0.15,"z_min":0.47,"z_max":0.135})
		right_shoulder = JointController.new(skeleton,Bones.SHOULDER_RIGHT_BONE,{"x_min":0.2,"x_max":0.3,"y_min":0.15,"y_max":0.5,"z_min":0.135,"z_max":0.47})
		left_elbow = JointController.new(skeleton,Bones.ELBOW_LEFT_BONE,{"y_min":0.766,"y_max":0.072})
		right_elbow = JointController.new(skeleton,Bones.ELBOW_RIGHT_BONE,{"y_min":0.072,"y_max":0.766})
		
		both_collars = DoubleJoint.new(left_collar,right_collar,[1])
		both_shoulders = DoubleJoint.new(left_shoulder,right_shoulder,[1])
		both_elbows = DoubleJoint.new(left_elbow,right_elbow,[1])
		
		hips = JointController.new(skeleton,Bones.HIPS_BONE,{"x_min":1,"x_max":1,"y_min":1,"y_max":1,"z_min":1,"z_max":1})
		pelvis = JointController.new(skeleton,Bones.PELVIS_BONE,{"y_min":0.123,"y_max":0.123,"z_min":0.150,"z_max":0.150})
		abdomen = JointController.new(skeleton,Bones.ABDOMEN_BONE_2,{"x_min":0.260,"x_max":0.260,"y_min":0.160,"y_max":0.160,"z_min":0.160,"z_max":0.160})
		neck = JointController.new(skeleton,Bones.NECK_BONE)
		
		left_hip = JointController.new(skeleton,Bones.HIP_LEFT_BONE,{"x_min":0.545,"x_max":0.290,"y_min":0.1,"y_max":0.15,"z_min":0.11,"z_max":0.19})
		right_hip = JointController.new(skeleton,Bones.HIP_RIGHT_BONE,{"x_min":0.545,"x_max":0.290,"y_min":0.15,"y_max":0.1,"z_min":0.19,"z_max":0.11})
		left_knee = JointController.new(skeleton,Bones.KNEE_LEFT_BONE,{"x_min":0.033,"x_max":0.695})
		right_knee = JointController.new(skeleton,Bones.KNEE_RIGHT_BONE,{"x_min":0.033,"x_max":0.695})
		left_ankle = JointController.new(skeleton,Bones.ANKLE_LEFT_BONE,{"x_min":0.09,"x_max":0.307,"y_min":0.27,"y_max":0.15,"z_min":0.09,"z_max":0.09})
		right_ankle = JointController.new(skeleton,Bones.ANKLE_RIGHT_BONE,{"x_min":0.09,"x_max":0.307,"y_min":0.15,"y_max":0.27,"z_min":0.09,"z_max":0.09})
	
		left_index = JointController.new(skeleton,Bones.LEFT_INDEX,{"x_min":0.09,"x_max":0.307,"y_min":0.15,"y_max":0.27})
		
		both_hips = DoubleJoint.new(left_hip,right_hip,[1])
		both_knees = DoubleJoint.new(left_knee,right_knee,[1])
		both_ankles = DoubleJoint.new(left_ankle,right_ankle,[1])


func create_springs(skeleton: Skeleton3D) -> void:
	add_head_spring("head",skeleton,Bones.NECK_BONE)
	add_torso_spring("torso",skeleton,Bones.ABDOMEN_BONE_1)

	add_breast_spring("left",skeleton,Bones.BREAST_LEFT_BONE,0.8)
	add_breast_spring("right",skeleton,Bones.BREAST_RIGHT_BONE,1.2)
	
	add_shoulder_spring("left",skeleton,Bones.SHOULDER_LEFT_BONE)
	add_shoulder_spring("right",skeleton,Bones.SHOULDER_RIGHT_BONE)


func create_iks(skeleton: Skeleton3D,parent: Node3D)-> void:
	add_limb_ik(skeleton,parent,_left_arm,Bones.SHOULDER_LEFT_BONE,"LeftArm","Hand",Vector3(0.2,1,-0.5))
	add_limb_ik(skeleton,parent,_right_arm,Bones.SHOULDER_RIGHT_BONE,"RightArm","Hand",Vector3(-0.2,1,-0.5))
	
	add_limb_ik(skeleton,parent,_left_leg,Bones.HIP_LEFT_BONE,"LeftLeg","Foot",Vector3(0.1,1,1))
	add_limb_ik(skeleton,parent,_right_leg,Bones.HIP_RIGHT_BONE,"RightLeg","Foot",Vector3(-0.1,1,1))


func add_limb_ik(skeleton: Skeleton3D,parent: Node3D,controller: Node,start_bone: int,node_name: String,target_name: String,pole_position: Vector3):
	var ik_node := TwoBoneIK3D.new()
	ik_node.name = node_name + "IK"
	ik_node.set_setting_count(1)
	ik_node.set_root_bone(0,start_bone)
	ik_node.set_middle_bone(0,start_bone+1)
	ik_node.set_end_bone(0,start_bone+2)
	ik_node.active = false
	
	var container := Node.new()
	container.name = "IK"
	controller.add_child(container)
	container.owner = parent
	
	var target_node := MeshInstance3D.new()
	target_node.name = target_name
	container.add_child(target_node)
	target_node.owner = parent
	
	if target_name == "Foot":
		var toes := MeshInstance3D.new()
		toes.name = "Toes"
		toes.position = Vector3(0,0,.25)
		add_placeholder(toes,Color(1,0,0),0.01)
		
		target_node.add_child(toes)
		toes.owner = parent
		
		var ik_toes := LookAtModifier3D.new()
		ik_toes.bone = start_bone+3
		ik_toes.target_node = toes.get_path()
		skeleton.add_child(ik_toes)
		ik_toes.owner = parent
	
	var pole_node := MeshInstance3D.new()
	pole_node.name = "Pole"
	pole_node.position = pole_position
	container.add_child(pole_node)
	pole_node.owner = parent
	
	add_placeholder(pole_node,Color(0,1,0))
	add_placeholder(target_node,Color(1,0,0))
	
	ik_node.set_pole_node(0,pole_node.get_path())
	ik_node.set_target_node(0,target_node.get_path())
	
	skeleton.add_child(ik_node)
	ik_node.owner = parent
	
	controller.ik = ik_node
	#controller.ik_bone = handle
	controller.ik_target = target_node


func add_placeholder(mesh: MeshInstance3D,color: Color,radius: float = 0.025) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color =  color
	material.no_depth_test = true
	
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.rings = 8
	sphere.radial_segments = 16
	sphere.material = material
	
	mesh.mesh = sphere
	mesh.visible = Engine.is_editor_hint()


func create_controllers( )-> void:
	_left_arm = PersonArm.new("LeftArm",left_collar,left_shoulder,left_elbow,self)
	_right_arm = PersonArm.new("RightArm",right_collar,right_shoulder,right_elbow,self)
	
	_left_leg = PersonLeg.new("LeftLeg",pelvis,left_hip,left_knee,left_ankle,self)
	_right_leg = PersonLeg.new("RightLeg",pelvis,right_hip,right_knee,right_ankle,self)
	
	_left_leg.weight_on_changed.connect(weight_on_changed)
	_right_leg.weight_on_changed.connect(weight_on_changed)


func create_center_of_gravity(skeleton: Skeleton3D,parent: Node3D) -> void:
	var cog = CenterOfGravity.new(skeleton,)
	cog.name = "CoG"
	cog.left_leg = find_child("LeftLeg")
	cog.right_leg = find_child("RightLeg")
	
	add_child(cog)
	cog.owner = parent
	
	#if Engine.is_editor_hint():
	#	cog.mesh = parent.find_child("CoG")


func create_collisions(parent: Node3D,skeleton: Skeleton3D):
	add_physical_bone(skeleton,59,parent)
	add_physical_bone(skeleton,38,parent)
	
	add_physical_bone(skeleton,Bones.HAND_LEFT_BONE,parent,_left_arm)
	add_physical_bone(skeleton,Bones.HAND_RIGHT_BONE,parent,_right_arm)
	
	add_physical_bone(skeleton,Bones.TOE_LEFT_BONE,parent,_left_leg)
	add_physical_bone(skeleton,Bones.TOE_RIGHT_BONE,parent,_right_leg)


func create_collisions_shapes(skeleton: Skeleton3D,mesh: MeshInstance3D):
	var shapes := GenerateCollisionShape.new()
	shapes.use_capsules = true
	shapes.remove_existing_collision_shapes = true
	shapes.generate_shapes(skeleton,skeleton,mesh)


func get_bones_vertices(surfaces: Array,bones_number: int) -> Dictionary:
	var bones_vertices := {}
	
	for i in surfaces.size():
		var vertices : PackedVector3Array = surfaces[i]["vertices"]
		if vertices.size() > 0:
			var bones : PackedInt32Array = surfaces[i]["bones"]
			var weights : PackedFloat32Array = surfaces[i]["weights"]
			for v in vertices.size() / 3:
				for c in 3:
					for b in bones_number:
						var bone = bones[v*24+c*8+b]
						var weight = weights[v*24+c*8+b]
						
						if weight >= 0.15:
							if !bones_vertices.has(bone):
								bones_vertices[bone] = PackedVector3Array( )
								
							bones_vertices[bone].push_back( vertices[v*3] )
							bones_vertices[bone].push_back( vertices[v*3+1] )
							bones_vertices[bone].push_back( vertices[v*3+2] )
	
	return bones_vertices


func add_physical_bone(skeleton: Skeleton3D,bone_idx: int,parent: Node3D,limb : PersonLimb = null) -> void:
	var bone_name := skeleton.get_bone_name(bone_idx)
	var bone = BoneAttachment3D.new()
	bone.name = bone_name
	bone.bone_idx = bone_idx
	
	var area = PersonHandle.new()
	area.name = bone_name
	area.collision_layer = XRToolsFunctionPickup.DEFAULT_GRAB_MASK
	#if bones_vertices.size() > 0:
	#	bone.spring_pusher = add_spring_pusher(bone_name,skeleton.find_child(name),collision,parent)
	bone.add_child(area)
	
	if limb:
		area.limb = limb
		limb.ik_bone = bone
		limb.ik_bone_idx = bone_idx
	
	skeleton.add_child(bone)
	bone.owner = parent
	area.owner = parent


func add_spring_pusher(pusher_name:String,bone: SpringBoneSimulator3D,shape: CollisionShape3D,parent: Node3D):
	var pusher := SpringPusher.new(bone,shape)
	pusher.name = pusher_name
	
	self.add_child(pusher)
	pusher.owner = parent
	
	return pusher


func create_bone_shape(bone: int,bones_vertices: Dictionary,horizontal: bool) -> CollisionShape3D:
	#return create_bone_full_mesh(bone,bones_vertices,horizontal)
	return create_bone_capsule(bone,bones_vertices,horizontal)


func create_bone_capsule(bone: int,bones_vertices: Dictionary,horizontal: bool) -> CollisionShape3D:
	var vertices : Array = bones_vertices[bone]

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from_arrays(arrays)

	var shape := CapsuleShape3D.new()	
	if horizontal:
		shape.radius = surface_tool.get_aabb().size.y / 2
		shape.height = surface_tool.get_aabb().size.x
	else:
		shape.radius = surface_tool.get_aabb().size.x / 2
		shape.height = surface_tool.get_aabb().size.y
	
	var collision := CollisionShape3D.new( )
	if horizontal:
		collision.rotate_z(PI/2)
		
	collision.position = surface_tool.get_aabb().get_center()
	collision.shape = shape
	collision.name = _skeleton.get_bone_name(bone)
	
	return collision


func create_bone_full_mesh(bone: int,bones_vertices: Dictionary,horizontal: bool) -> CollisionShape3D:
	var mesh := ProceduralMesh.new()
	var vertices : Array = bones_vertices[bone]

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from_arrays(arrays)
	surface_tool.commit(mesh)
	
	var collision := CollisionShape3D.new( )
	collision.shape = mesh.create_trimesh_shape( )
	collision.name = _skeleton.get_bone_name(bone)
	
	return collision


func duplicate_skeleton(parent: Node3D,skeleton: Skeleton3D,name: String)-> Skeleton3D:
	var new_skeleton := Skeleton3D.new()
	new_skeleton.name = name
	
	for i in skeleton.get_bone_count():
		new_skeleton.add_bone(skeleton.get_bone_name(i))
		new_skeleton.set_bone_parent(i,skeleton.get_bone_parent(i))
		new_skeleton.set_bone_rest(i,skeleton.get_bone_rest(i))
		new_skeleton.set_bone_pose_position(i,skeleton.get_bone_pose_position(i))
		new_skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i))
	
	if parent:
		parent.add_child(new_skeleton)
		new_skeleton.owner = parent
	
	return new_skeleton


func add_head_spring(name:String,skeleton: Skeleton3D,bone: int):
	add_spring(name,skeleton,bone,1,2.0,1.0)


func add_torso_spring(name:String,skeleton: Skeleton3D,bone: int):
	add_spring(name,skeleton,bone,4,4,0.8)


func add_breast_spring(name:String,skeleton: Skeleton3D,bone: int,variance: float):
	add_spring(name+"_breast",skeleton,bone,0,0.5,0.12)
	pass


func add_shoulder_spring(name:String,skeleton: Skeleton3D,bone: int):
	add_spring(name+"_collar",skeleton,bone,1,1.0,0.5)
	add_spring(name+"_elbow",skeleton,bone+1,1,1.0,0.2)
	add_spring(name+"_wrist",skeleton,bone+2,1,1.0,0.2)


func add_spring(name: String,skeleton: Skeleton3D,bone: int,chain_length: int,stiffness: float,drag: float):
	var spring := SpringBoneSimulator3D.new()
	spring.setting_count = 1
	spring.set_root_bone(0,bone)
	spring.set_end_bone(0,bone+chain_length)
	if chain_length == 0:
		spring.set_extend_end_bone(0,true)
		spring.set_end_bone_length(0,0.2)
		spring.set_end_bone_direction(0,SpringBoneSimulator3D.BONE_DIRECTION_PLUS_Z)
	spring.set_radius(0,0.02)
	spring.set_stiffness(0,stiffness)
	spring.set_drag(0,drag)
	spring.set_enable_all_child_collisions(0,false)
	spring.active = true;
	
	skeleton.add_child(spring)
	spring.name = name
	spring.owner = skeleton.get_parent()
