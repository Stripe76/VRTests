@tool
class_name VAMActor extends Node3D

@export_tool_button("Generate","Add") var generate_action = generate_model

@export_range(0,5) var eyes_color : float = 0:
	set(value):
		eyes_color = value
		if _mesh:
			_mesh.eye_template.set_eye_color(eyes_color)
	get:
		return eyes_color
#@onready var _genitals := $VAMVagina

var _mesh : VAMMesh
var _hair : VAMHair
var _skeleton : VAMSkeleton
var _person_controller : PersonController

var _mesh_thread : Thread
var _materials_thread : Thread


func _ready() -> void:
	print("--- VAMActor._ready")
	
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		generate_model()


func generate_model():
	var daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Barbie/","Saves/scene/Barbie.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Keiko/","Saves/scene/JUN/KEIKO/Keiko.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Anita/","Saves/scene/Anita.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Rubyrose/","Saves/scene/Rubyrose.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","ddaamm.hair_short5.4/Custom/Hair/Female/ddaamm/ddaamm/ddaamm short5 bang.vab")
	
	#load_scene(daz_model,null,"","","")


func _exit_tree():
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	if _materials_thread:
		_materials_thread.wait_to_finish()


func load_scene(daz_model: Daz3DMesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,materials : bool = true):
	load_scene_pre()
	load_scene_sync(daz_model,library_folder,scene_folder,scene_file,hair_file,false)
	load_scene_done(library_folder,scene_folder,scene_file,true)


func load_scene_async(daz_model: Daz3DMesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,materials : bool = true):
	load_scene_pre()
	
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	else:
		_mesh_thread = Thread.new()
	_mesh_thread.start(load_scene_sync.bind(daz_model,library_folder,scene_folder,scene_file,hair_file,true))


func load_scene_pre():
	if _skeleton:
		remove_child(_skeleton)
		_skeleton.queue_free()
	if _person_controller:
		remove_child(_person_controller)
		_person_controller.queue_free()


func load_scene_sync(daz_model: Daz3DMesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,call_done: bool):
	_skeleton = load_skeleton(daz_model,library_folder,scene_folder,scene_file)
	_mesh = load_mesh(daz_model,scene_folder,scene_file,library_folder+hair_file,_skeleton.left_eye_bone_origin,_skeleton.right_eye_bone_origin)
	
	if call_done:
		call_deferred("load_scene_done",library_folder,scene_folder,scene_file,true)


func load_scene_done(library_folder: String,scene_folder: String,scene_file: String,async: bool):
	add_child(_skeleton)
	_skeleton.add_child(_mesh)
	
	_person_controller = add_person_controller(_skeleton,_mesh)
	
	_skeleton.owner = self
	_mesh.owner = self
	_person_controller.owner = self
	
	if async:
		load_materials_async(library_folder,scene_folder,scene_file)
	else:
		load_materials(library_folder,scene_folder,scene_file)


func add_person_controller(skeleton: VAMSkeleton,mesh: VAMMesh )-> PersonController:
	var person_controller = PersonController.new(skeleton)
	person_controller.name = "PersonController"
	
	person_controller._left_eye_aabb = mesh.left_eye_aabb
	person_controller._right_eye_aabb = mesh.right_eye_aabb

	add_child(person_controller)
	person_controller.owner = self
	
	person_controller.initialize(self,skeleton)
	
	#if $Movements and $PersonController:
	#	$Movements.person_controller = $PersonController
	return person_controller


func load_skeleton(base_model: Daz3DMesh,_library_folder: String,scene_folder: String,scene_file: String) -> VAMSkeleton:
	var skeleton := VAMSkeleton.new()
	skeleton.name = "VAMSkeleton"
	
	skeleton.load_skeleton(base_model,scene_folder,scene_file)
	
	return skeleton


func load_mesh(daz_model: Daz3DMesh,scene_folder: String,scene_file: String,hair_file: String,left_eye_bone_origin: Vector3,right_eye_bone_origin: Vector3) -> VAMMesh:
	var vam_mesh = VAMMesh.new()
	vam_mesh.name = "VAMMEsh"
	
	vam_mesh.left_eye_bone = left_eye_bone_origin + Vector3(0,0,-0.005)
	vam_mesh.right_eye_bone = right_eye_bone_origin+ Vector3(0,0,-0.005)
	
	vam_mesh.load_mesh(daz_model,scene_folder,scene_file)
	vam_mesh.mesh = vam_mesh.full_body
	
	return vam_mesh


func load_hair(hair_file: String,head_tris: Dictionary):
	var parent : Node3D = _skeleton.find_child("head 25")
	if not parent:
		parent = self
	
	parent.add_child(_hair)
	_hair.owner = self
	
	head_tris["Origin"] = parent.position
	
	_hair.generate_hair(hair_file,head_tris)


func load_materials(library_folder: String,scene_folder: String,scene_file: String):
	_mesh.load_materials(library_folder,scene_folder,scene_file)
	
	#if _genitals and _genitals._mesh_material:
		#_genitals._mesh_material.set_shader_parameter("texture_albedo",_mesh.genitals_material.get_shader_parameter("texture_albedo"))
		#_genitals._mesh_material.set_shader_parameter("texture_normal",_mesh.genitals_material.get_shader_parameter("texture_normal"))
		#_genitals._mesh_material.set_shader_parameter("standard_decal",_mesh.genitals_material.get_shader_parameter("standard_decal"))


func load_materials_async(library_folder: String,scene_folder: String,scene_file: String):
	if _materials_thread:
		_materials_thread.wait_to_finish()
	else:
		_materials_thread = Thread.new()
	_materials_thread.start(load_materials.bind(library_folder,scene_folder,scene_file))
