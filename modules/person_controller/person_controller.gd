@tool
class_name PersonController extends Node3D

const MESH_MASK := 0b0000_0000_0000_0000_0000_0001_0000_0000
const CAPSULE_MASK := 0b0000_0000_0000_0100_0000_0000_0000_0101

@export_tool_button("Reset","Reload") var reset_action = reset_pose

@export_group("Root")
@export var enable_X : bool
@export var enable_Y : bool
@export var enable_Z : bool
@export var enable_rotation : bool

@export_group("Ragdoll")
@export var enable_ragdoll : bool:
	set(value):
		enable_ragdoll = value
		
		var simulator : PhysicalBoneSimulator3D = _skeleton.get_node("Ragdoll")
		if simulator:
			if value:
				simulator.physical_bones_start_simulation()
			else:
				simulator.physical_bones_stop_simulation()
			random_push(simulator.get_node("hip"),-.5)
			random_push(simulator.get_node("head"),1.2)
			random_push(simulator.get_node("chest"),.5)
			random_push(simulator.get_node("lHand"),.2)
			random_push(simulator.get_node("rHand"),.2)
	get:
		return enable_ragdoll


@export_group("Head")
@export var head : JointController
@export var neck : JointController
@export var left_eye : JointController
@export var right_eye : JointController

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
@export var body : JointController
@export var hips : JointController
@export var pelvis : JointController
@export var abdomen_1 : JointController
@export var abdomen_2 : JointController
@export var chest : JointController

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


var _current_root : PersonLimb

var _skeleton : Skeleton3D

var _person: Person

var _head: PersonHead
var _torso: PersonTorso

var _left_arm: PersonArm
var _right_arm: PersonArm

var _left_leg: PersonLeg
var _right_leg: PersonLeg

var _left_eye_aabb: AABB
var _right_eye_aabb: AABB


var _editor_owner
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			_editor_owner = owner
			owner = null
		NOTIFICATION_EDITOR_POST_SAVE:
			owner = _editor_owner


func _init(skeleton: Skeleton3D) -> void:
	print("--- PersonController._init")
	_skeleton = skeleton
	if _skeleton:
		#_skeleton.add_child(self)
		#self.owner = _skeleton
		
		#_skeleton_pose = duplicate_skeleton(parent,skeleton,"SkeletonPose")
		#_skeleton_springs = duplicate_skeleton(parent,skeleton,"SkeletonSprings")
		
		_skeleton.skeleton_updated.connect(_on_skeleton_updated)


func _physics_process(_delta: float) -> void:
	#if _skeleton and not _current_root:
		#last_delta_pos *= 1.0 - (0.1 * _delta)
		#print(last_delta_pos)
		
		#_skeleton.global_transform.origin += last_delta_pos * _delta
	pass


func _on_skeleton_updated():
	update_root_on()


func random_push(bone: PhysicalBone3D,forward: float):
	if bone:
		var angle := randf_range(0.0,2.0 * PI)
		var push_direction := Vector3(cos(angle),0.0,forward)
		var push_force := 2500.0 * absf(forward)
		
		bone.apply_central_impulse(push_direction * push_force)
		
		var random_spin := Vector3(randf_range(-2.0, 2.0), randf_range(-5.0, 5.0), randf_range(-2.0, 2.0))
		bone.angular_velocity = random_spin


func root_on_changed(limb: PersonLimb, root_on: bool):
	if root_on:
		if _current_root and _current_root != limb:
			_current_root.root_on = false
				
		_current_root = limb
		
		# Memorizza l'orientamento globale del nuovo piede nel frame esatto dell'ancoraggio
		if _skeleton and _current_root:
			_current_root.ro_y_rotation = _skeleton.get_bone_global_pose(_current_root.ik_bone_idx).basis.get_euler().y
	elif limb == _current_root:
		_current_root = null


var last_delta_pos : Vector3
func update_root_on(apply : bool = true) -> Vector3:
	if _skeleton and _current_root:
		var foot_position : Vector3 = _current_root.ik_bone.global_position
		var delta_position : Vector3 = _current_root.ro_position - foot_position
		
		last_delta_pos = delta_position
		
		if apply:
			var bone_pose : Transform3D = _skeleton.get_bone_global_pose(_current_root.ik_bone_idx)
			var foot_y_rotation = bone_pose.basis.get_euler().y
			var delta_rotation : float = _current_root.ro_y_rotation - foot_y_rotation
			
			if abs(delta_rotation) > 0.001 and enable_rotation:
				# IL FULCRO (PIVOT): Usiamo la posizione di ancoraggio fissa a terra
				var world_pivot = _current_root.ro_position
				
				# Trova la distanza vettoriale tra l'origine globale dello scheletro e il piede a terra
				var offset_skeleton = _skeleton.global_transform.origin - world_pivot
				
				# Ruota lo scheletro sul proprio asse globale
				_skeleton.global_rotate(Vector3.UP,delta_rotation)
				
				# RIPOSIZIONAMENTO ATTORNAL AL PIVOT:
				# Ruotiamo l'offset e riposizioniamo lo scheletro in modo che il perno sia il piede
				_skeleton.global_transform.origin = world_pivot + offset_skeleton.rotated(Vector3.UP,delta_rotation)
				
				# Aggiorna il valore di riferimento per il frame successivo
				_current_root.ro_y_rotation = foot_y_rotation
				
				# Ricalcola la trasformazione globale e il delta_pos DOPO aver spostato e ruotato lo scheletro,
				# altrimenti la traslazione finale userebbe i vettori sfasati del frame precedente
				bone_pose = _skeleton.get_bone_global_pose(_current_root.ik_bone_idx)
				foot_position = _skeleton.global_transform * bone_pose.origin
				delta_position = _current_root.ro_position - foot_position
			
			if not enable_X:
				delta_position.x = 0
			if not enable_Y:
				delta_position.y = 0
			if not enable_Z:
				delta_position.z = 0
			_skeleton.global_transform.origin += delta_position
			
		return delta_position
	return Vector3()


func update_position(new_root_on: int)-> int:
	if _skeleton:
		var parent : Node3D = _skeleton.get_parent()
		if parent:
			var position1 := update_root_on(false)
			#print(position1)
	
			var position2 := update_root_on(false)
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
	return new_root_on


func reset_pose():
	_current_root = null
	
	#if _skeleton:
		#_skeleton.position = Vector3()
		#_skeleton.get_parent().position = Vector3()
	
	head.reset_pose()
	neck.reset_pose()
	left_collar.reset_pose()
	right_collar.reset_pose()
	left_shoulder.reset_pose()
	right_shoulder.reset_pose()
	left_elbow.reset_pose()
	right_elbow.reset_pose()
	hips.reset_pose()
	pelvis.reset_pose()
	abdomen_1.reset_pose()
	abdomen_2.reset_pose()
	chest.reset_pose()
	left_hip.reset_pose()
	right_hip.reset_pose()
	left_knee.reset_pose()
	right_knee.reset_pose()
	left_ankle.reset_pose()
	right_ankle.reset_pose()
	
	_left_arm.ik_on = false
	_right_arm.ik_on = false
	_left_leg.ik_on = false
	_right_leg.ik_on = false
	
	if _skeleton:
		_skeleton.position = Vector3.ZERO;
		_skeleton.rotation = Vector3.ZERO;


func initialize(parent: Node3D,skeleton: Skeleton3D,mesh: MeshInstance3D) -> void:
	set_eye_bones(skeleton)
	
	create_springs(skeleton)
	create_joints(skeleton)
	
	create_controllers( )
	create_collisions(parent,skeleton,mesh)
	create_center_of_gravity(skeleton,parent)
	create_iks(skeleton,parent)
	
	reset_pose()


func set_eye_bones(skeleton: Skeleton3D):
	var origin = _left_eye_aabb.get_center() - skeleton.get_bone_global_rest(Bones.HEAD_BONE).origin
	skeleton.set_bone_rest(Bones.EYE_LEFT_BONE,Transform3D(Basis( ),origin))
	skeleton.set_bone_pose_position(Bones.EYE_LEFT_BONE,origin)
	
	origin = _right_eye_aabb.get_center() - skeleton.get_bone_global_rest(Bones.HEAD_BONE).origin
	skeleton.set_bone_rest(Bones.EYE_RIGHT_BONE,Transform3D(Basis( ),origin))
	skeleton.set_bone_pose(Bones.EYE_RIGHT_BONE,Transform3D(Basis( ),origin))


func create_joints(skeleton: Skeleton3D) -> void:
		body = JointController.new(skeleton,Bones.ROOT)
		
		head = JointController.new(skeleton,Bones.HEAD_BONE,{"x_min":0.18,"x_max":0.05,"y_min":0.15,"y_max":0.15,"z_min":0.05,"z_max":0.05})
		neck = JointController.new(skeleton,Bones.NECK_BONE,{"x_min":0.15,"x_max":0.20,"y_min":0.20,"y_max":0.20,"z_min":0.05,"z_max":0.05})
		left_eye = JointController.new(skeleton,Bones.EYE_LEFT_BONE,{"x_min":0.15,"x_max":0.15,"y_min":0.15,"y_max":0.15})
		right_eye = JointController.new(skeleton,Bones.EYE_RIGHT_BONE,{"x_min":0.15,"x_max":0.15,"y_min":0.15,"y_max":0.15})
		
		left_collar = JointController.new(skeleton,Bones.COLLAR_LEFT_BONE,{"x_min":0.1,"x_max":0.05,"y_min":0.15,"y_max":0.05,"z_min":0.053,"z_max":0.24},_skeleton.get_node_or_null("left_collar"),2)
		right_collar = JointController.new(skeleton,Bones.COLLAR_RIGHT_BONE,{"x_min":0.05,"x_max":0.1,"y_min":0.05,"y_max":0.15,"z_min":0.24,"z_max":0.053},_skeleton.get_node_or_null("right_collar"),2)
		left_shoulder = JointController.new(skeleton,Bones.SHOULDER_LEFT_BONE,{"x_min":0.3,"x_max":0.2,"y_min":0.5,"y_max":0.15,"z_min":0.47,"z_max":0.16},_skeleton.get_node_or_null("left_shoulder"))
		right_shoulder = JointController.new(skeleton,Bones.SHOULDER_RIGHT_BONE,{"x_min":0.2,"x_max":0.3,"y_min":0.15,"y_max":0.5,"z_min":0.16,"z_max":0.47},_skeleton.get_node_or_null("right_shoulder"))
		left_elbow = JointController.new(skeleton,Bones.ELBOW_LEFT_BONE,{"y_min":0.766,"y_max":0.072},_skeleton.get_node_or_null("left_elbow"))
		right_elbow = JointController.new(skeleton,Bones.ELBOW_RIGHT_BONE,{"y_min":0.072,"y_max":0.766},_skeleton.get_node_or_null("right_elbow"))
		
		both_collars = DoubleJoint.new(left_collar,right_collar,[1])
		both_shoulders = DoubleJoint.new(left_shoulder,right_shoulder,[1])
		both_elbows = DoubleJoint.new(left_elbow,right_elbow,[1])
		
		hips = JointController.new(skeleton,Bones.HIPS_BONE,{"x_min":1,"x_max":1,"y_min":1,"y_max":1,"z_min":1,"z_max":1})
		pelvis = JointController.new(skeleton,Bones.PELVIS_BONE,{"y_min":0.123,"y_max":0.123,"z_min":0.150,"z_max":0.150})
		abdomen_1 = JointController.new(skeleton,Bones.ABDOMEN_BONE_1,{"x_min":0.260,"x_max":0.260,"y_min":0.160,"y_max":0.160,"z_min":0.160,"z_max":0.160})
		abdomen_2 = JointController.new(skeleton,Bones.ABDOMEN_BONE_2,{"x_min":0.260,"x_max":0.260,"y_min":0.160,"y_max":0.160,"z_min":0.160,"z_max":0.160})
		chest = JointController.new(skeleton,Bones.CHEST_BONE,{"x_min":0.260,"x_max":0.260,"y_min":0.160,"y_max":0.160,"z_min":0.160,"z_max":0.160},_skeleton.get_node_or_null("torso"))
		
		left_hip = JointController.new(skeleton,Bones.HIP_LEFT_BONE,{"x_min":0.545,"x_max":0.290,"y_min":0.25,"y_max":0.25,"z_min":0.11,"z_max":0.19})
		right_hip = JointController.new(skeleton,Bones.HIP_RIGHT_BONE,{"x_min":0.545,"x_max":0.290,"y_min":0.25,"y_max":0.25,"z_min":0.19,"z_max":0.11})
		left_knee = JointController.new(skeleton,Bones.KNEE_LEFT_BONE,{"x_min":0.033,"x_max":0.695})
		right_knee = JointController.new(skeleton,Bones.KNEE_RIGHT_BONE,{"x_min":0.033,"x_max":0.695})
		left_ankle = JointController.new(skeleton,Bones.ANKLE_LEFT_BONE,{"x_min":0.29,"x_max":0.307,"y_min":0.27,"y_max":0.15,"z_min":0.09,"z_max":0.09})
		right_ankle = JointController.new(skeleton,Bones.ANKLE_RIGHT_BONE,{"x_min":0.29,"x_max":0.307,"y_min":0.15,"y_max":0.27,"z_min":0.09,"z_max":0.09})
	
		left_index = JointController.new(skeleton,Bones.LEFT_INDEX,{"x_min":0.09,"x_max":0.307,"y_min":0.15,"y_max":0.27})
		
		both_hips = DoubleJoint.new(left_hip,right_hip,[1])
		both_knees = DoubleJoint.new(left_knee,right_knee,[1])
		both_ankles = DoubleJoint.new(left_ankle,right_ankle,[1])


func create_springs(skeleton: Skeleton3D) -> void:
	add_head_spring("head_spring",skeleton,Bones.NECK_BONE)
	add_torso_spring("torso",skeleton,Bones.ABDOMEN_BONE_1)

	add_breast_spring("left",skeleton,Bones.BREAST_LEFT_BONE,0.8)
	add_breast_spring("right",skeleton,Bones.BREAST_RIGHT_BONE,1.2)
	
	add_arm_spring("left",skeleton,Bones.COLLAR_LEFT_BONE)
	add_arm_spring("right",skeleton,Bones.COLLAR_RIGHT_BONE)

	#add_leg_spring("left",skeleton,Bones.HIP_LEFT_BONE)
	#add_leg_spring("right",skeleton,Bones.HIP_RIGHT_BONE)


func create_iks(skeleton: Skeleton3D,parent: Node3D)-> void:
	var container : Node3D = skeleton.find_child("IKControllers")
	if not container:
		container = Node3D.new()
		container.name = "IKControllers"
		skeleton.add_child(container)
		container.owner = parent
		container.visible = false

	add_head_ik(skeleton,parent,container,_head,Bones.HEAD_BONE,Bones.EYE_LEFT_BONE,Bones.EYE_RIGHT_BONE)
	
	add_limb_ik(skeleton,parent,container,"Left","Arm","Hand",_left_arm,Bones.SHOULDER_LEFT_BONE,0,Vector3(0.2,1,-0.5))
	add_limb_ik(skeleton,parent,container,"Right","Arm","Hand",_right_arm,Bones.SHOULDER_RIGHT_BONE,0,Vector3(-0.2,1,-0.5))
	
	add_limb_ik(skeleton,parent,container,"Left","Leg","Foot",_left_leg,Bones.HIP_LEFT_BONE,0,Vector3(0.1,1,1))
	add_limb_ik(skeleton,parent,container,"Right","Leg","Foot",_right_leg,Bones.HIP_RIGHT_BONE,0,Vector3(-0.1,1,1))


func create_controllers( )-> void:
	_person = Person.new("Person",_skeleton,self)
	
	_head = PersonHead.new("Head",head,neck,left_eye,right_eye,self)
	
	_left_arm = PersonArm.new("LeftArm",1,left_collar,left_shoulder,left_elbow,self)
	_right_arm = PersonArm.new("RightArm",-1,right_collar,right_shoulder,right_elbow,self)
	
	_torso = PersonTorso.new("Torso",body,hips,pelvis,abdomen_1,abdomen_2,chest,self)
	
	_left_leg = PersonLeg.new("LeftLeg",1,hips,pelvis,left_hip,left_knee,left_ankle,self)
	_right_leg = PersonLeg.new("RightLeg",-1,hips,pelvis,right_hip,right_knee,right_ankle,self)
	
	_left_leg.root_on_changed.connect(root_on_changed)
	_right_leg.root_on_changed.connect(root_on_changed)


func create_collisions(parent: Node3D,skeleton: Skeleton3D,mesh: MeshInstance3D):
	var simulator : PhysicalBoneSimulator3D
	if mesh:
		simulator = PhysicalBoneSimulator3D.new()
		simulator.name = "Ragdoll"
		simulator.influence = 0.95
		
		skeleton.add_child(simulator)
		simulator.owner = parent
	
	# Head
	add_physical_bone(Bones.HEAD_BONE,skeleton,parent,simulator,head)
	
	# Arms
	add_physical_bone(Bones.COLLAR_LEFT_BONE,skeleton,parent,simulator,null)
	add_physical_bone(Bones.COLLAR_RIGHT_BONE,skeleton,parent,simulator,null)
	add_physical_bone(Bones.SHOULDER_LEFT_BONE,skeleton,parent,simulator,left_shoulder)
	add_physical_bone(Bones.SHOULDER_RIGHT_BONE,skeleton,parent,simulator,right_shoulder)
	add_physical_bone(Bones.ELBOW_LEFT_BONE,skeleton,parent,simulator,left_elbow)
	add_physical_bone(Bones.ELBOW_RIGHT_BONE,skeleton,parent,simulator,right_elbow)
	add_physical_bone(Bones.HAND_LEFT_BONE,skeleton,parent,simulator,null,Vector3.ONE,false,_left_arm)
	add_physical_bone(Bones.HAND_RIGHT_BONE,skeleton,parent,simulator,null,Vector3.ONE,false,_right_arm)
	
	# Torso	
	add_physical_bone(Bones.HIPS_BONE,skeleton,parent,simulator,null)
	add_physical_bone(Bones.PELVIS_BONE,skeleton,parent,simulator,null,Vector3.ONE,true)
	add_physical_bone(Bones.ABDOMEN_BONE_1,skeleton,parent,simulator,null)
	add_physical_bone(Bones.ABDOMEN_BONE_2,skeleton,parent,simulator,abdomen_2,Vector3(.1,.1,.1))
	add_physical_bone(Bones.CHEST_BONE,skeleton,parent,simulator,null)
	
	# Legs
	add_physical_bone(Bones.HIP_LEFT_BONE,skeleton,parent,simulator,left_hip)
	add_physical_bone(Bones.HIP_RIGHT_BONE,skeleton,parent,simulator,right_hip)
	add_physical_bone(Bones.KNEE_LEFT_BONE,skeleton,parent,simulator,left_knee)
	add_physical_bone(Bones.KNEE_RIGHT_BONE,skeleton,parent,simulator,right_knee)
	add_physical_bone(Bones.ANKLE_LEFT_BONE,skeleton,parent,simulator,left_ankle,Vector3.ONE,false,_left_leg)
	add_physical_bone(Bones.ANKLE_RIGHT_BONE,skeleton,parent,simulator,right_ankle,Vector3.ONE,false,_right_leg)
	add_physical_bone(Bones.TOE_LEFT_BONE,skeleton,parent,simulator)
	add_physical_bone(Bones.TOE_RIGHT_BONE,skeleton,parent,simulator)
	
	if simulator:
		create_collisions_shapes(skeleton,simulator,mesh)


func create_collisions_shapes(skeleton: Skeleton3D,simulator: PhysicalBoneSimulator3D,mesh: MeshInstance3D):
	var shapes := GenerateCollisionShape.new()
	shapes.remove_existing_collision_shapes = true
	#shapes.generate_shapes(skeleton,skeleton,mesh,"Mesh")
	shapes.use_capsules = true
	shapes.generate_shapes(skeleton,simulator,mesh,"Capsule")


func add_head_ik(skeleton: Skeleton3D,parent: Node3D,container : Node3D,controller: Node,head_bone: int,left_eye_bone: int,right_eye_bone: int):
	var ik_head := LookAtModifier3D.new()
	ik_head.name = "HeadIK"
	ik_head.bone = head_bone
	ik_head.active = false
	
	var ik_left_eye := LookAtModifier3D.new()
	ik_left_eye.name = "LeftEyeIK"
	ik_left_eye.bone = left_eye_bone
	ik_left_eye.active = true
	ik_left_eye.use_angle_limitation = true
	ik_left_eye.symmetry_limitation = true
	ik_left_eye.primary_limit_angle = deg_to_rad(55)
	ik_left_eye.secondary_limit_angle = deg_to_rad(25)
	
	var ik_right_eye := LookAtModifier3D.new()
	ik_right_eye.name = "RightEyeIK"
	ik_right_eye.bone = right_eye_bone
	ik_right_eye.active = true
	ik_right_eye.use_angle_limitation = true
	ik_right_eye.symmetry_limitation = true
	ik_right_eye.primary_limit_angle = deg_to_rad(55)
	ik_right_eye.secondary_limit_angle = deg_to_rad(25)
	
	var target_origin := Node3D.new()
	target_origin.name = "LookAtOrigin"
	target_origin.position = Vector3(0,1.65,0)
	container.add_child(target_origin)
	target_origin.owner = parent
	
	var target_head := MeshInstance3D.new()
	target_head.name = "LookAtHead"
	target_head.position = Vector3(0,0,1)
	add_placeholder(target_head,Color(0,0,1),0.025)
	
	var target_eyes := MeshInstance3D.new()
	target_eyes.name = "LookAtEyes"
	target_eyes.position = Vector3(0,1.65,1)
	add_placeholder(target_eyes,Color(0,0,1),0.025)
	var target_left_eye := Node3D.new()
	target_left_eye.name = "LeftEye"
	target_left_eye.position = Vector3(0.025,0,0)
	var target_right_eye := Node3D.new()
	target_right_eye.name = "RightEye"
	target_right_eye.position = Vector3(-0.025,0,0)
	
	target_origin.add_child(target_head)
	target_head.owner = parent
	
	container.add_child(target_eyes)
	target_eyes.owner = parent
	target_eyes.add_child(target_left_eye)
	target_eyes.add_child(target_right_eye)
	target_left_eye.owner = parent
	target_right_eye.owner = parent
	
	ik_head.set_target_node(target_head.get_path())
	ik_left_eye.set_target_node(target_left_eye.get_path())
	ik_right_eye.set_target_node(target_right_eye.get_path())
	
	skeleton.add_child(ik_head)
	skeleton.add_child(ik_left_eye)
	skeleton.add_child(ik_right_eye)
	ik_head.owner = parent
	ik_left_eye.owner = parent
	ik_right_eye.owner = parent
	
	controller.ik_head = ik_head
	controller.ik_left_eye = ik_left_eye
	controller.ik_right_eye = ik_right_eye
	controller.ik_target_head = target_origin
	controller.ik_target_eyes = target_eyes


func add_limb_ik(skeleton: Skeleton3D,parent: Node3D,container : Node3D,side: String,limb: String,handle: String,controller: PersonLimb,start_bone: int,last_bone_offset: int,pole_position: Vector3):
	var ik_node := TwoBoneIK3D.new()
	ik_node.name = side+limb+"IK"
	ik_node.set_setting_count(1)
	ik_node.set_root_bone(0,start_bone)
	ik_node.set_middle_bone(0,start_bone+1)
	ik_node.set_end_bone(0,start_bone+2+last_bone_offset)
	ik_node.active = false
	
	var target_origin := Node3D.new()
	target_origin.name = side+handle+"Local"
	#target_origin.position = Vector3(0,1.65,0)
	container.add_child(target_origin)
	target_origin.owner = parent
	
	var target_node := MeshInstance3D.new()
	target_node.name = side+handle+"Global"
	target_node.top_level = true
	target_origin.add_child(target_node)
	target_node.owner = parent
	
	#if target_name == "Foot":
		#var toes := MeshInstance3D.new()
		#toes.name = "Toes"
		#toes.position = Vector3(0,0,.25)
		#add_placeholder(toes,Color(1,0,0),0.01)
		#
		#target_node.add_child(toes)
		#toes.owner = parent
		#
		#var ik_toes := LookAtModifier3D.new()
		#ik_toes.bone = start_bone+3
		#ik_toes.target_node = toes.get_path()
		#skeleton.add_child(ik_toes)
		#ik_toes.owner = parent
	
	var pole_node := MeshInstance3D.new()
	pole_node.name = side+limb+"Pole"
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
	controller.local_target = target_origin
	controller.global_target = target_node
	
	if controller.ik_bone:
		controller.local_target.position = Vector3(0,controller.ik_bone.position.y,0)
		controller.local_target.global_position = controller.local_target.global_position


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


func create_center_of_gravity(skeleton: Skeleton3D,parent: Node3D) -> void:
	var cog = CenterOfGravity.new(skeleton,)
	cog.name = "CoG"
	cog.left_leg = find_child("LeftLeg")
	cog.right_leg = find_child("RightLeg")
	
	add_child(cog)
	cog.owner = parent
	
	#if Engine.is_editor_hint():
	#	cog.mesh = parent.find_child("CoG")


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


func add_physical_bone(bone_idx: int,
						skeleton: Skeleton3D,
						parent: Node3D,
						simulator: PhysicalBoneSimulator3D = null,
						joint: JointController = null,
						multiplier: Vector3 = Vector3.ONE,
						no_collision: bool = false,
						limb : PersonLimb = null) -> void:
	var bone_name := skeleton.get_bone_name(bone_idx)
	var bone = BoneAttachment3D.new()
	bone.name = bone_name
	bone.bone_idx = bone_idx

	var mesh = Area3D.new()
	mesh.name = "Mesh"
	mesh.collision_layer = MESH_MASK
	bone.add_child(mesh)
	
	var capsule = PersonHandle.new()
	capsule.name = "Capsule"
	capsule.collision_layer = CAPSULE_MASK
	#if bones_vertices.size() > 0:
	#	bone.spring_pusher = add_spring_pusher(bone_name,skeleton.find_child(name),collision,parent)
	bone.add_child(capsule)
	
	if limb:
		capsule.limb = limb
		limb.ik_bone = bone
		limb.ik_bone_idx = bone_idx
	
	skeleton.add_child(bone)
	bone.owner = parent
	mesh.owner = parent
	capsule.owner = parent
	
	if simulator:
		var physical_bone := PhysicalBone3D.new()
		physical_bone.name = bone_name + ("_noshape" if no_collision else "")
		physical_bone.bone_name = bone_name
		physical_bone.mass = 1000 if bone_name == "head" or bone_name == "hip" or bone_name == "lHand" or bone_name == "rHand" else 100
		physical_bone.bounce = 0.10
		physical_bone.friction = 0.95
		physical_bone.linear_damp = 2.50
		physical_bone.linear_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
		physical_bone.angular_damp = 4.50
		physical_bone.angular_damp_mode = PhysicalBone3D.DAMP_MODE_REPLACE
		
		if joint:
			joint.apply_limits_to_physical_bone(physical_bone,1.0,multiplier)
		else:
			physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF

		var bone_rest_transform: Transform3D = skeleton.get_bone_global_rest(bone_idx)
		physical_bone.transform = bone_rest_transform
		
		simulator.add_child(physical_bone)
		physical_bone.owner = parent


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


func duplicate_skeleton(parent: Node3D,skeleton: Skeleton3D,skeleton_name: String)-> Skeleton3D:
	var new_skeleton := Skeleton3D.new()
	new_skeleton.name = skeleton_name
	
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


func add_head_spring(spring:String,skeleton: Skeleton3D,bone: int):
	add_spring(spring,skeleton,bone,1,2.0,1.0)


func add_torso_spring(spring:String,skeleton: Skeleton3D,bone: int):
	add_spring(spring,skeleton,bone,4,4,0.8).active = false


func add_breast_spring(spring:String,skeleton: Skeleton3D,bone: int,_variance: float):
	add_spring(spring+"_breast",skeleton,bone,0,0.5,0.12)


func add_arm_spring(spring:String,skeleton: Skeleton3D,bone: int):
	add_spring(spring+"_collar",skeleton,bone,1,3.5,0.5)
	add_spring(spring+"_shoulder",skeleton,bone+1,1,1.0,0.2)
	add_spring(spring+"_elbow",skeleton,bone+2,1,1.0,0.2)
	add_spring(spring+"_wrist",skeleton,bone+3,1,1.0,0.2)


func add_leg_spring(name:String,skeleton: Skeleton3D,bone: int):
	add_spring(name+"_hip",skeleton,bone,1,1.0,0.5)
	add_spring(name+"_knee",skeleton,bone+1,1,1.0,0.2)
	add_spring(name+"_ankle",skeleton,bone+2,1,1.0,0.2)


func add_spring(name: String,skeleton: Skeleton3D,bone: int,chain_length: int,stiffness: float,drag: float) -> SpringBoneSimulator3D:
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
	
	return spring
