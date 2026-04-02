@tool
class_name PersonController
extends Node3D

@export_tool_button("Reset","Reload") var reset_action = reset_pose
	
@export var weight_on : int = 0:
	set(value): 
		if weight_on != value:
			weight_on = update_position(value)
	get: return weight_on
@export var left_foot_origin : Vector3
@export var right_foot_origin : Vector3

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
@export var skeleton : Skeleton3D
@export var skeleton_pose : Skeleton3D
@export var skeleton_springs : Skeleton3D
@export_range(0,1) var lerp := 0.0:
	set(value): 
		lerp = value
		update_skeleton(skeleton)


func _init(skeleton: Skeleton3D,parent: Node3D) -> void:
	self.skeleton = skeleton
	if skeleton:
		#skeleton.add_child(self)
		#self.owner = skeleton
		skeleton_pose = skeleton
		skeleton_springs = skeleton
		
		#skeleton_pose = duplicate_skeleton(parent,skeleton,"SkeletonPose")
		#skeleton_springs = duplicate_skeleton(parent,skeleton,"SkeletonSprings")
		
		#skeleton_springs.skeleton_updated.connect(_on_skeleton_updated)
		
		left_foot_origin = skeleton.get_bone_global_rest(Bones.ANKLE_LEFT_BONE).origin
		right_foot_origin = skeleton.get_bone_global_rest(Bones.ANKLE_RIGHT_BONE).origin
		
		add_head_spring("head",skeleton_springs,Bones.NECK_BONE)
		add_torso_spring("torso",skeleton_springs,Bones.ABDOMEN_BONE_1)

		add_breast_spring("left",skeleton_springs,Bones.BREAST_LEFT_BONE,0.8)
		add_breast_spring("right",skeleton_springs,Bones.BREAST_RIGHT_BONE,1.2)
		
		add_shoulder_spring("left",skeleton_springs,Bones.SHOULDER_LEFT_BONE)
		add_shoulder_spring("right",skeleton_springs,Bones.SHOULDER_RIGHT_BONE)
		
		skeleton = skeleton_pose
		
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
		pelvis = JointController.new(skeleton,Bones.PELVIS_BONE,{"y_min":0.123,"y_max":0.123,"z_min":0.050,"z_max":0.050})
		abdomen = JointController.new(skeleton,Bones.ABDOMEN_BONE_2,{"x_min":0.260,"x_max":0.260,"y_min":0.160,"y_max":0.160,"z_min":0.160,"z_max":0.160})
		neck = JointController.new(skeleton,Bones.NECK_BONE)
		
		left_hip = JointController.new(skeleton,Bones.HIP_LEFT_BONE,{"x_min":0.545,"x_max":0.290,"y_min":0.1,"y_max":0.15,"z_min":0.11,"z_max":0.19})
		right_hip = JointController.new(skeleton,Bones.HIP_RIGHT_BONE,{"x_min":0.545,"x_max":0.290,"y_min":0.15,"y_max":0.1,"z_min":0.19,"z_max":0.11})
		left_knee = JointController.new(skeleton,Bones.KNEE_LEFT_BONE,{"x_min":0.033,"x_max":0.695})
		right_knee = JointController.new(skeleton,Bones.KNEE_RIGHT_BONE,{"x_min":0.033,"x_max":0.695})
		left_ankle = JointController.new(skeleton,Bones.ANKLE_LEFT_BONE,{"x_min":0.09,"x_max":0.307,"y_min":0.27,"y_max":0.15})
		right_ankle = JointController.new(skeleton,Bones.ANKLE_RIGHT_BONE,{"x_min":0.09,"x_max":0.307,"y_min":0.15,"y_max":0.27})
	
		left_index = JointController.new(skeleton,Bones.LEFT_INDEX,{"x_min":0.09,"x_max":0.307,"y_min":0.15,"y_max":0.27})
		
		both_hips = DoubleJoint.new(left_hip,right_hip,[1])
		both_knees = DoubleJoint.new(left_knee,right_knee,[1])
		both_ankles = DoubleJoint.new(left_ankle,right_ankle,[1])


var do_that := true
#func _process(delta: float) -> void:

func _physics_process(delta: float) -> void:
	if do_that:
		cippa(weight_on)
	do_that = true
	#update_skeleton(skeleton)
	#update_position( weight_on );
	pass


var poses := {}
func _on_skeleton_updated():
	var count := skeleton_springs.get_bone_count()
	for i in count:
		poses[i] = skeleton_springs.get_bone_pose_rotation(i)
	update_position( weight_on );


func _process_modification() -> void:
	##print("_process_modification")
	#update_skeleton(skeleton)
	pass


func create_collisions(parent: Node3D,skeleton: Skeleton3D, surfaces: Array,bones_number: int ):
	var bones_vertices := get_bones_vertices(surfaces,bones_number)

	var physical_skeleton := PhysicalBoneSimulator3D.new()
	physical_skeleton.name = "PhysicalBones"
	skeleton.add_child(physical_skeleton)
	physical_skeleton.owner = parent
	
	add_physical_bone("left_collar",physical_skeleton,skeleton,59,bones_vertices,parent)
	add_physical_bone("right_collar",physical_skeleton,skeleton,38,bones_vertices,parent)

	#add_physical_bone("left_collar",physical_skeleton,skeleton,60,bones_vertices,parent)


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


func add_physical_bone(name: String,physical_skeleton : PhysicalBoneSimulator3D,skeleton: Skeleton3D,bone_idx: int,bones_vertices: Dictionary,parent: Node3D):
	var collision := create_bone_shape(bone_idx,bones_vertices,true)
	var bone_global = skeleton.get_bone_global_pose(bone_idx)
	var bone_inverse = bone_global.affine_inverse()
	
	var bone = VAMPhysicalBone3D.new()
	bone.name = skeleton.get_bone_name(bone_idx)
	bone.body_offset = bone_inverse
	bone.spring_pusher = add_spring_pusher(name,skeleton.find_child(name),collision,parent)
	
	print(bone.spring_pusher)
	
	bone.set( "bone_name",skeleton.get_bone_name(bone_idx))
	bone.add_child(collision)
	
	physical_skeleton.add_child(bone)
	bone.owner = parent
	collision.owner = parent


func add_spring_pusher(name:String,bone: SpringBoneSimulator3D,shape: CollisionShape3D,parent: Node3D):
	var pusher := SpringPusher.new(bone,shape)
	pusher.name = name
	
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
	collision.name = skeleton.get_bone_name(bone)
	
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
	collision.name = skeleton.get_bone_name(bone)
	
	return collision


func update_skeleton(skeleton: Skeleton3D):
	pass
	print("update_skeleton")
	var count := skeleton.get_bone_count()
	for i in count:
		var pos_pose := skeleton_pose.get_bone_pose_position(i)
		var pos_spring = poses[i]
		var position = lerp(pos_pose,pos_spring,0)
		
		skeleton.set_bone_pose_position(i,position)
		
		skeleton_springs.set_bone_pose_position(0,skeleton.position)
	
		var rot_pose := skeleton_pose.get_bone_pose_rotation(i)
		var rot_spring = poses[i]
		#var rotation = lerp(rot_pose,rot_spring,lerp)
		var rotation = rot_pose+(rot_spring)
		
		skeleton.set_bone_pose_rotation(i,rotation)


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


func cippa(current_weight_on: int,apply : bool = true) -> Vector3:
	if skeleton:
		var diff : Vector3
		if current_weight_on == 1:
			diff = left_foot_origin - skeleton.get_bone_global_pose(Bones.ANKLE_LEFT_BONE).origin
		elif current_weight_on == 2:
			diff = right_foot_origin - skeleton.get_bone_global_pose(Bones.ANKLE_RIGHT_BONE).origin
		if diff and apply:
			diff.x = 0
			diff.z = 0
			skeleton.position = diff
		return diff
	return Vector3()


func update_position(new_weight_on: int)-> int:
	if skeleton:
		var parent : Node3D = skeleton.get_parent()
		if parent:
			var position1 := cippa(weight_on,false)
			#print(position1)
	
			var position2 := cippa(new_weight_on,false)
			#print(position2)
	
			var posDelta := Vector3()
			#posDelta.x = position1.x - position2.x
			posDelta.y = position1.y - position2.y
			#posDelta.z = position1.z - position2.z
			#position.z = - position2.z*2
			#parent.position += posDelta
			
			#b = false
	return new_weight_on


func reset_pose():
	weight_on = 0
	
	if skeleton:
		skeleton.position = Vector3()
		skeleton.get_parent().position = Vector3()
	
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


func add_head_spring(name:String,skeleton: Skeleton3D,bone: int):
	add_spring(name,skeleton,bone,1,2.0,1.0)


func add_torso_spring(name:String,skeleton: Skeleton3D,bone: int):
	add_spring(name,skeleton,bone,4,2.3,1.0)


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
