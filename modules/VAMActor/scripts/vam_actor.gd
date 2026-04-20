@tool
class_name VAMActor extends Node3D

@export_tool_button("Generate","Add") var generate_action = generate_model

@export var look_at_target: Node3D
@export_range(0,5) var eyes_color : float = 0:
	set(value):
		if left_eye:
			left_eye.eye_color = value
		if right_eye:
			right_eye.eye_color = value
	get: return left_eye.eye_color

@onready var left_eye : VAMEye = load("res://modules/VAMActor/vam_eye.tscn").instantiate()
@onready var right_eye : VAMEye = load("res://modules/VAMActor/vam_eye.tscn").instantiate()

var _mesh := VAMMesh.new()
var _hair := VAMHair.new()
var _skeleton := VAMSkeleton.new()

var _mesh_thread : Thread
var _materials_thread : Thread


func _ready() -> void:
	print("--- VAMActor._ready")

	_mesh.name = "VAMMesh"
	_hair.name = "VAMHair"
	_skeleton.name = "VAMSkeleton"
	_skeleton.skeleton_updated.connect( skeleton_updated )
	
	left_eye.name = "LeftEye"
	right_eye.name = "RightEye"
	
	if Engine.is_editor_hint() and false:
		left_eye.transform = left_eye.transform.scaled_local(Vector3(0.035,0.035,0.035))
		right_eye.transform = left_eye.transform.scaled_local(Vector3(0.035,0.035,0.035))
	
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		generate_model()


func _process(_delta: float) -> void:
	if look_at_target:
		left_eye.look_at(look_at_target.global_position,Vector3(0,1,0),true)
		right_eye.look_at(look_at_target.global_position,Vector3(0,1,0),true)
		#right_eye.rotation = left_eye.rotation

	#if skeleton.get_bone_count() > 0:
	#	left_eye.position = skeleton.get_bone_global_pose(Bones.EYE_LEFT_BONE).origin
	#	right_eye.position = skeleton.get_bone_global_pose(Bones.EYE_RIGHT_BONE).origin


func generate_model():
	var daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")
	
	load_scene(daz_model,null,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Barbie/","Saves/scene/Barbie.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,null,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Anita/","Saves/scene/Anita.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,null,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,null,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","Gina/Custom/Hair/Female/RenVR/RenVR/Jessica Alva (REN).vab")
	#load_scene(daz_model,null,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","ddaamm.hair_short5.4/Custom/Hair/Female/ddaamm/ddaamm/ddaamm short5 bang.vab")
	
	#load_scene(daz_model,null,"","","")


func skeleton_updated() -> void:
	if _skeleton.get_bone_count() > 0:
		left_eye.position = _skeleton.get_bone_global_pose(Bones.EYE_LEFT_BONE).origin
		right_eye.position = _skeleton.get_bone_global_pose(Bones.EYE_RIGHT_BONE).origin


func _exit_tree():
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
		#mesh_thread.free()
	if _materials_thread:
		_materials_thread.wait_to_finish()
		#materials_thread.free()


func load_scene(daz_model: Daz3DMesh,genitals_model: Mesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,materials : bool = true):
	load_skeleton(daz_model)
	
	load_mesh(daz_model,genitals_model,scene_folder,scene_file,library_folder+hair_file)
	if materials:
		load_materials_async(library_folder,scene_folder,scene_file)
	
	add_person_controller( )


func add_person_controller( )-> void:
	var person_controller = PersonController.new(_skeleton)
	person_controller.name = "PersonController"
	
	self.add_child(person_controller)
	self.move_child(person_controller,self.get_child_count()-2)
	person_controller.owner = self
	person_controller.initialize(self,_skeleton)
	
	#if $Movements and $PersonController:
	#	$Movements.person_controller = $PersonController


func load_skeleton(base_model: Daz3DMesh):
	_skeleton.load_skeleton(base_model)

	self.add_child(_skeleton)
	_skeleton.owner = self

	if _skeleton.get_child_count() == 0:
		_skeleton.add_child(_mesh)
		_mesh.owner = self

		_skeleton.add_child(left_eye)
		left_eye.owner = self
		_skeleton.add_child(right_eye)
		right_eye.owner = self

	left_eye.set_offset(left_eye.position - _skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin)
	right_eye.set_offset(right_eye.position - _skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin)


func load_mesh_async(daz_model: Daz3DMesh,genitals_model: Mesh,scene_folder: String,scene_file: String,hair_file: String):
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	else:
		_mesh_thread = Thread.new()
	_mesh_thread.start(load_mesh.bind(daz_model,genitals_model,scene_folder,scene_file,hair_file))


func load_mesh_async_done(hair_file: String):
	_mesh.mesh = _mesh.full_body
	
	if _mesh.left_eye:
		set_eye_position(left_eye,_mesh.left_eye)
	if _mesh.right_eye:
		set_eye_position(right_eye,_mesh.right_eye)
	
	if _skeleton.get_bone_count() > 0:
		left_eye.set_offset(left_eye.position - _skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin)
		right_eye.set_offset(right_eye.position - _skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin)
		
		var person_controller : PersonController = find_child("PersonController")
		if person_controller:
			person_controller.create_collisions_shapes(_skeleton,_mesh)
			
			load_hair(hair_file,_mesh.head_tris)


func load_mesh(daz_model: Daz3DMesh,genitals_model: Mesh,scene_folder: String,scene_file: String,hair_file: String):
	_mesh.load_mesh(daz_model,genitals_model,scene_folder,scene_file)
	
	call_deferred("load_mesh_async_done",hair_file)


func load_hair(hair_file: String,head_tris: Dictionary):
	var parent : Node3D = _skeleton.find_child("head 25")
	if not parent:
		parent = self
	
	parent.add_child(_hair)
	_hair.owner = self
	
	head_tris["Origin"] = parent.position
	
	_hair.generate_hair(hair_file,head_tris)


func load_materials_async(library_folder: String,scene_folder: String,scene_file: String):
	if _materials_thread:
		_materials_thread.wait_to_finish()
	else:
		_materials_thread = Thread.new()
	_materials_thread.start(load_materials.bind(library_folder,scene_folder,scene_file))


func load_materials(library_folder: String,scene_folder: String,scene_file: String):
	_mesh.load_materials(library_folder,scene_folder,scene_file)


func set_eye_position(eye_node: VAMEye,eye_mesh: Mesh):
	var aabb : AABB = eye_mesh.get_aabb()
	var eye_position := aabb.position
	var size := aabb.size
	if size.x > 0:
		var ratio = 1 / (0.035 / size.x)
		eye_position.x += size.x / 2
		eye_position.y += size.y / 2
		eye_position.z += size.z / 2 - 0.003
		eye_node.position = eye_position
		eye_node.scale = Vector3(ratio,ratio,ratio);


func add_breast_spring(skeleton: Skeleton3D,bone: int,_variance: float):
	add_spring(skeleton,bone,0,0.5,0.12)


func add_shoulder_spring(skeleton: Skeleton3D,bone: int):
	add_spring(skeleton,bone,1,1.0,0.2)
	add_spring(skeleton,bone+1,1,1.0,0.2)
	add_spring(skeleton,bone+2,1,1.0,0.2)


func add_spring(skeleton: Skeleton3D,bone: int,chain_length: int,stiffness: float,drag: float):
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
	spring.active = true;

	skeleton.add_child(spring)
	spring.owner = skeleton
