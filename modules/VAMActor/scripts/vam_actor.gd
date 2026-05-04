@tool
class_name VAMActor extends Node3D

@export_tool_button("Generate","Add") var generate_action = generate_model

@export_range(0,5) var eyes_color : float = 0:
	set(value):
		eyes_color = value
		_mesh.eye_template.set_eye_color(eyes_color)
	get:
		return eyes_color
#@onready var _genitals := $VAMVagina

var _mesh := VAMMesh.new()
var _hair := VAMHair.new()
var _skeleton := VAMSkeleton.new()

var _left_eye_bone_origin : Vector3
var _right_eye_bone_origin : Vector3

var _mesh_thread : Thread
var _materials_thread : Thread


func _ready() -> void:
	print("--- VAMActor._ready")

	_mesh.name = "VAMMesh"
	_hair.name = "VAMHair"
	#_genitals.name = "VAMGenitals"
	_skeleton.name = "VAMSkeleton"
	
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		generate_model()


func generate_model():
	var daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")
	load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Barbie/","Saves/scene/Barbie.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Anita/","Saves/scene/Anita.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Rubyrose/","Saves/scene/Rubyrose.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","ddaamm.hair_short5.4/Custom/Hair/Female/ddaamm/ddaamm/ddaamm short5 bang.vab")
	
	#load_scene(daz_model,null,"","","")


func _exit_tree():
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
		#mesh_thread.free()
	if _materials_thread:
		_materials_thread.wait_to_finish()
		#materials_thread.free()


func load_scene(daz_model: Daz3DMesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,materials : bool = true):
	load_skeleton(daz_model)
	
	load_mesh(daz_model,scene_folder,scene_file,library_folder+hair_file)
	if materials:
		load_materials_async(library_folder,scene_folder,scene_file)
	
	add_person_controller( )


func add_person_controller( )-> void:
	var person_controller = PersonController.new(_skeleton)
	person_controller.name = "PersonController"
	person_controller._left_eye_aabb = _mesh.left_eye_aabb
	person_controller._right_eye_aabb = _mesh.right_eye_aabb
	
	self.add_child(person_controller)
	self.move_child(person_controller,self.get_child_count()-2)
	person_controller.owner = self
	person_controller.initialize(self,_skeleton)
	
	#if $Movements and $PersonController:
	#	$Movements.person_controller = $PersonController


func load_skeleton(base_model: Daz3DMesh):
	_skeleton.load_skeleton(base_model)
	
	_left_eye_bone_origin = _skeleton.get_bone_global_rest(Bones.EYE_LEFT_BONE).origin
	_right_eye_bone_origin = _skeleton.get_bone_global_rest(Bones.EYE_RIGHT_BONE).origin
	
	self.add_child(_skeleton)
	_skeleton.owner = self
		
	if _skeleton.get_child_count() == 0:
		_skeleton.add_child(_mesh)
		_mesh.owner = self
		
		#_skeleton.add_child(_genitals)
		#_genitals.owner = self


func load_mesh_async(daz_model: Daz3DMesh,scene_folder: String,scene_file: String,hair_file: String):
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	else:
		_mesh_thread = Thread.new()
	_mesh_thread.start(load_mesh.bind(daz_model,scene_folder,scene_file,hair_file))


func load_mesh_async_done(hair_file: String):
	_mesh.mesh = _mesh.full_body
	#_genitals.set_genital_mesh(_mesh.genitals)
	#_genitals.skeleton = $VAMSkeleton.get_path()
	#
	#_mesh.body_material.set_shader_parameter("lattice_size_A",_genitals.left_size)
	#_mesh.body_material.set_shader_parameter("lattice_offset_A",_genitals.left_offset)
	#_mesh.body_material.set_shader_parameter("lattice_A",_genitals._mesh_material.get_shader_parameter("lattice_A"))
	#
	#_mesh.body_material.set_shader_parameter("lattice_size_B",_genitals.right_size)
	#_mesh.body_material.set_shader_parameter("lattice_offset_B",_genitals.right_offset)
	#_mesh.body_material.set_shader_parameter("lattice_B",_genitals._mesh_material.get_shader_parameter("lattice_B"))
	
	if _skeleton.get_bone_count() > 0:
		var person_controller : PersonController = find_child("PersonController")
		if person_controller:
			person_controller._left_eye_aabb = _mesh.left_eye_aabb
			person_controller._right_eye_aabb = _mesh.right_eye_aabb
			
			person_controller.set_eye_bones(_skeleton)
			person_controller.create_collisions_shapes(_skeleton,_mesh)
			
			if not Engine.is_editor_hint():
				load_hair(hair_file,_mesh.head_tris)


func load_mesh(daz_model: Daz3DMesh,scene_folder: String,scene_file: String,hair_file: String):
	_mesh.left_eye_bone = _left_eye_bone_origin + Vector3(0,0,-0.006)
	_mesh.right_eye_bone = _right_eye_bone_origin + Vector3(0,0,-0.006)
	
	_mesh.load_mesh(daz_model,scene_folder,scene_file)
	
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
	
	#if _genitals and _genitals._mesh_material:
		#_genitals._mesh_material.set_shader_parameter("texture_albedo",_mesh.genitals_material.get_shader_parameter("texture_albedo"))
		#_genitals._mesh_material.set_shader_parameter("texture_normal",_mesh.genitals_material.get_shader_parameter("texture_normal"))
		#_genitals._mesh_material.set_shader_parameter("standard_decal",_mesh.genitals_material.get_shader_parameter("standard_decal"))


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
