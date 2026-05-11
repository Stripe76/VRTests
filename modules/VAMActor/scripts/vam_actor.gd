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

@onready var _daz_model : Daz3DMesh = load("res://modules/VAMActor/resources/Genesis2Female.dsf")

var _mesh : VAMMesh
var _hair : VAMHair
var _skeleton : VAMSkeleton
var _person_controller : PersonController

var _mesh_thread : Thread
var _materials_thread : Thread


func _ready() -> void:
	if Engine.is_editor_hint() and not get_parent() is Node3D:
		generate_model()


func generate_model():
	#load_scene(_daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Barbie/","Saves/scene/Barbie.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	load_scene(_daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Keiko/","Saves/scene/JUN/KEIKO/Keiko.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(_daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Anita/","Saves/scene/Anita.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(_daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(_daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Rubyrose/","Saves/scene/Rubyrose.json","Barbie/Custom/Hair/Female/RenVR/Barbie.vab")
	#load_scene(_daz_model,"/mnt/data/Projects/Godot/library/","/mnt/data/Projects/Godot/library/Viola/","Saves/scene/Viola.json","ddaamm.hair_short5.4/Custom/Hair/Female/ddaamm/ddaamm/ddaamm short5 bang.vab")
	
	#load_scene(_daz_model,null,"","","")


func _exit_tree():
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	if _materials_thread:
		_materials_thread.wait_to_finish()


func load_looks(library: LibraryManager,looksID: int):
	load_looks_pre()
	load_looks_sync(library,looksID)


func load_looks_async(library: LibraryManager,looksID: int,signal_done: Callable = Callable()):
	_mutex.lock()
	if _loading_scene or _loading_material:
		return
	_loading_scene = true
	_mutex.unlock()
	
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	else:
		_mesh_thread = Thread.new()
	
	load_scene_pre()
	
	_mesh_thread.start(load_looks_sync.bind(library,looksID,signal_done))


func load_looks_pre():
	if _skeleton:
		remove_child(_skeleton)
		_skeleton.queue_free()
	if _person_controller:
		remove_child(_person_controller)
		_person_controller.queue_free()


func load_looks_sync(library: LibraryManager,looksID: int,signal_done: Callable = Callable()):
	_skeleton = load_skeleton_new(_daz_model,library,looksID)
	_mesh = load_mesh_new(_daz_model,library,looksID,_skeleton.left_eye_bone_origin,_skeleton.right_eye_bone_origin)
	
	call_deferred("load_looks_done",library,looksID,true)
	
	if signal_done:
		signal_done.call()


func load_looks_done(library: LibraryManager,looksID: int,async: bool):
	add_child(_skeleton)
	_skeleton.add_child(_mesh)
	
	_person_controller = add_person_controller(_skeleton,_mesh)
	
	_skeleton.owner = self
	_mesh.owner = self
	_person_controller.owner = self
	
	if async:
		load_materials_async_new(library,looksID)
	else:
		load_materials_new(library,looksID)
	
	#_mutex.lock()
	_loading_scene = false
	#_mutex.unlock()


func load_materials_new(library: LibraryManager,looksID: int):
	_mesh.load_materials_new(library,looksID)
	
	#if _genitals and _genitals._mesh_material:
		#_genitals._mesh_material.set_shader_parameter("texture_albedo",_mesh.genitals_material.get_shader_parameter("texture_albedo"))
		#_genitals._mesh_material.set_shader_parameter("texture_normal",_mesh.genitals_material.get_shader_parameter("texture_normal"))
		#_genitals._mesh_material.set_shader_parameter("standard_decal",_mesh.genitals_material.get_shader_parameter("standard_decal"))
	
	#_mutex.lock()
	_loading_material = false
	#_mutex.unlock()


func load_materials_async_new(library: LibraryManager,looksID: int):
	_mutex.lock()
	if _loading_material:
		return
	_loading_material = true
	_mutex.unlock()
	
	if _materials_thread:
		_materials_thread.wait_to_finish()
	else:
		_materials_thread = Thread.new()
	_materials_thread.start(load_materials_new.bind(library,looksID))


func load_scene(daz_model: Daz3DMesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,materials : bool = true):
	load_scene_pre()
	load_scene_sync(daz_model,library_folder,scene_folder,scene_file,hair_file,false)
	load_scene_done(library_folder,scene_folder,scene_file,true)


var _mutex = Mutex.new()
var _loading_scene := false
var _loading_material := false
func load_scene_async(daz_model: Daz3DMesh,library_folder: String,scene_folder: String,scene_file: String,hair_file: String,materials : bool = true):
	_mutex.lock()
	if _loading_scene or _loading_material:
		return
	_loading_scene = true
	_mutex.unlock()
	
	if _mesh_thread:
		_mesh_thread.wait_to_finish()
	else:
		_mesh_thread = Thread.new()
	
	load_scene_pre()
	
	_mesh_thread.start(load_scene_sync.bind(daz_model,library_folder,scene_folder,scene_file,hair_file,true))


func load_scene_pre():
	if _mesh:
		_skeleton.remove_child(_mesh)
		_mesh.queue_free()
	if _skeleton:
		_skeleton.queue_free()
	if _person_controller:
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
	
	if async:
		load_materials_async(library_folder,scene_folder,scene_file)
	else:
		load_materials(library_folder,scene_folder,scene_file)
	
	#_mutex.lock()
	_loading_scene = false
	#_mutex.unlock()


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


func load_skeleton_new(base_model: Daz3DMesh,library: LibraryManager,looksID: int) -> VAMSkeleton:
	var skeleton := VAMSkeleton.new()
	skeleton.name = "VAMSkeleton"
	
	skeleton.load_skeleton_new(base_model,library,looksID)
	
	return skeleton


func load_mesh(daz_model: Daz3DMesh,scene_folder: String,scene_file: String,hair_file: String,left_eye_bone_origin: Vector3,right_eye_bone_origin: Vector3) -> VAMMesh:
	var vam_mesh = VAMMesh.new()
	vam_mesh.name = "VAMMEsh"
	
	vam_mesh.left_eye_bone = left_eye_bone_origin + Vector3(0,0,-0.005)
	vam_mesh.right_eye_bone = right_eye_bone_origin+ Vector3(0,0,-0.005)
	
	vam_mesh.load_mesh(daz_model,scene_folder,scene_file)
	vam_mesh.mesh = vam_mesh.full_body
	
	return vam_mesh


func load_mesh_new(daz_model: Daz3DMesh,library: LibraryManager,looksID: int,left_eye_bone_origin: Vector3,right_eye_bone_origin: Vector3) -> VAMMesh:
	var vam_mesh = VAMMesh.new()
	vam_mesh.name = "VAMMesh"
	
	vam_mesh.left_eye_bone = left_eye_bone_origin + Vector3(0,0,-0.005)
	vam_mesh.right_eye_bone = right_eye_bone_origin+ Vector3(0,0,-0.005)
	
	vam_mesh.load_mesh_new(daz_model,library,looksID)
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
	
	#_mutex.lock()
	_loading_material = false
	#_mutex.unlock()


func load_materials_async(library_folder: String,scene_folder: String,scene_file: String):
	_mutex.lock()
	if _loading_material:
		return
	_loading_material = true
	_mutex.unlock()
	
	if _materials_thread:
		_materials_thread.wait_to_finish()
	else:
		_materials_thread = Thread.new()
	_materials_thread.start(load_materials.bind(library_folder,scene_folder,scene_file))
