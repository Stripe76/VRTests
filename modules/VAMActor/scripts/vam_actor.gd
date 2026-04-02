@tool
class_name VAMActor
extends Node3D

@export var look_at: Node3D
@export_range(0,5) var eyes_color : float = 0:
	set(value):
		if left_eye:
			left_eye.eye_color = value
		if right_eye:
			right_eye.eye_color = value
	get: return left_eye.eye_color

@onready var left_eye : VAMEye = load("res://modules/VAMActor/vam_eye.tscn").instantiate()
@onready var right_eye : VAMEye = load("res://modules/VAMActor/vam_eye.tscn").instantiate()

var mesh := VAMMesh.new()
var skeleton := VAMSkeleton.new()

var mesh_thread : Thread
var materials_thread : Thread

func _ready() -> void:
	mesh.name = "VAMMesh"
	skeleton.name = "VAMSkeleton"

	left_eye.name = "LeftEye"
	right_eye.name = "RightEye"

	if Engine.is_editor_hint() and false:
		left_eye.transform = left_eye.transform.scaled_local(Vector3(0.035,0.035,0.035))
		right_eye.transform = left_eye.transform.scaled_local(Vector3(0.035,0.035,0.035))

	if Engine.is_editor_hint() and true:
		var daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")

		load_scene(daz_model,null,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Barbie/","Saves/scene/Barbie.json")
		#load_scene(daz_model,null,"","","")


var d : float
func _process(delta: float) -> void:
	if look_at:
		left_eye.look_at(look_at.global_position,Vector3(0,1,0),true)
		right_eye.look_at(look_at.global_position,Vector3(0,1,0),true)
		#right_eye.rotation = left_eye.rotation

	if skeleton.get_bone_count() > 0:
		left_eye.position = skeleton.get_bone_global_pose(Bones.EYE_LEFT_BONE).origin
		right_eye.position = skeleton.get_bone_global_pose(Bones.EYE_RIGHT_BONE).origin
		

		d += delta*5
		#if (d as int/1)%2 == 0:
		#self.rotation.y = sin(d*5.0)*0.30
		#self.position.y = 1+sin(d*10.0)*0.05
		#skeleton.set_bone_pose_rotation(21,Quaternion( Vector3(0,1,0 ),sin(d)/10 ))
		#skeleton.set_bone_pose_rotation(22,Quaternion( Vector3(0,1,0 ),sin(d)/6 ))
		#skeleton.set_bone_pose_rotation(24,Quaternion( Vector3(0,1,0 ),-sin(d)/8 ))
		#skeleton.set_bone_pose_rotation(25,Quaternion( Vector3(0,1,0 ),-sin(d)/12 ))
		#skeleton.set_bone_pose_rotation(SHOULDER_RIGHT_BONE,Quaternion( Vector3(0,0,1 ),-sin(d)/12 ))

		#skeleton.set_bone_pose_rotation(37,Quaternion( Vector3(0,1,0 ),-sin(d)/2 ))
		#skeleton.set_bone_pose_rotation(58,Quaternion( Vector3(0,1,0 ),-sin(d)/2 ))


func _exit_tree():
	if mesh_thread:
		mesh_thread.wait_to_finish()
		#mesh_thread.free()
	if materials_thread:
		materials_thread.wait_to_finish()
		#materials_thread.free()


func load_scene(daz_model: Daz3DMesh,genitals_model: Mesh,library_folder: String,scene_folder: String,scene_file: String,load_materials : bool = true):
	load_skeleton(daz_model)
	
	load_mesh(daz_model,genitals_model,scene_folder,scene_file)	
	if  load_materials:
		load_materials_async(library_folder,scene_folder,scene_file)
	
	add_person_controller( )


func add_person_controller( )-> void:
	var person_controller = PersonController.new(skeleton,self)
	person_controller.name = "PersonController"
	
	self.add_child(person_controller)
	self.move_child(person_controller,1)
	person_controller.owner = self
	
	person_controller.create_collisions(self,skeleton,mesh.mesh_surfaces,8)


func load_skeleton(base_model: Daz3DMesh):
	skeleton.load_skeleton(base_model)

	self.add_child(skeleton)
	skeleton.owner = self

	if skeleton.get_child_count() == 0:
		skeleton.add_child(mesh)
		mesh.owner = self

		skeleton.add_child(left_eye)
		left_eye.owner = self
		skeleton.add_child(right_eye)
		right_eye.owner = self

	left_eye.set_offset(left_eye.position - skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin)
	right_eye.set_offset(right_eye.position - skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin)


func load_mesh_async(daz_model: Daz3DMesh,genitals_model: Mesh,scene_folder: String,scene_file: String):
	if mesh_thread:
		mesh_thread.wait_to_finish()
	else:
		mesh_thread = Thread.new()
	mesh_thread.start(load_mesh.bind(daz_model,genitals_model,scene_folder,scene_file))


func load_mesh_async_done():
	mesh.mesh = mesh.full_body

	if mesh.left_eye:
		set_eye_position(left_eye,mesh.left_eye)
	if mesh.right_eye:
		set_eye_position(right_eye,mesh.right_eye)

	if skeleton.get_bone_count() > 0:
		left_eye.set_offset(left_eye.position - skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin)
		right_eye.set_offset(right_eye.position - skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin)


func load_mesh(daz_model: Daz3DMesh,genitals_model: Mesh,scene_folder: String,scene_file: String):
	mesh.load_mesh(daz_model,genitals_model,scene_folder,scene_file)

	call_deferred("load_mesh_async_done")


func load_materials_async(library_folder: String,scene_folder: String,scene_file: String):
	if materials_thread:
		materials_thread.wait_to_finish()
	else:
		materials_thread = Thread.new()
	materials_thread.start(load_materials.bind(library_folder,scene_folder,scene_file))


func load_materials(library_folder: String,scene_folder: String,scene_file: String):
	mesh.load_materials(library_folder,scene_folder,scene_file)
	pass


func set_eye_position(eye_node: VAMEye,eye_mesh: Mesh):
	var aabb : AABB = eye_mesh.get_aabb()
	var position := aabb.position
	var size := aabb.size
	if size.x > 0:
		var ratio = 1 / (0.035 / size.x)
		position.x += size.x / 2
		position.y += size.y / 2
		position.z += size.z / 2 - 0.003
		eye_node.position = position
		eye_node.scale = Vector3(ratio,ratio,ratio);


func add_breast_spring(skeleton: Skeleton3D,bone: int,variance: float):
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
